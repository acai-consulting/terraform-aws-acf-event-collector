# ---------------------------------------------------------------------------------------------------------------------
# ¦ VERSIONS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.0"
      configuration_aliases = []
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_caller_identity" "core_security" { provider = aws.core_security }
data "aws_caller_identity" "core_logging" { provider = aws.core_logging }


# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  eb_forwarding_iam_role_name = "test-event-collector-forwarder-role"
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ TEST DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "override" {
  # checkov:skip=CKV_AWS_109
  # checkov:skip=CKV_AWS_111
  # checkov:skip=CKV_AWS_356
  statement {
    sid    = "ReadPermissions"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.core_security.account_id}:root",
        "arn:aws:iam::${data.aws_caller_identity.core_logging.account_id}:root"
      ]
    }
    actions = [
      "kms:Describe*",
      "kms:List*",
      "kms:Get*",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "ManagementPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.core_security.account_id}:root"]
    }
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ MODULE
# ---------------------------------------------------------------------------------------------------------------------
module "central_collector" {
  source = "../../"

  settings = {
    central_eventbus = {
      name = "test"
      encyrption = {
        cmk_policy_override = [
          data.aws_iam_policy_document.override.json
        ]
      }
    }
    forwardings = {
      cw_lg = [
        {
          lg_name = "test-lg"
          lg_encyrption = {
            cmk_policy_override = [
              data.aws_iam_policy_document.override.json
            ]
          }
        }
      ]
    }
  }
  providers = {
    aws = aws.core_security
  }
}


module "event_sender1" {
  source = "../../member/terraform"

  member_settings = {
    event_collector = {
      central_eventbus_arn = module.central_collector.eventbus_arn
    }
    account_baseline = {
      eb_forwarding_iam_role = {
        name = local.eb_forwarding_iam_role_name
      }
      event_rules = [
        {
          name    = "failed_aws_backups"
          pattern = <<PATTERN
{
  "source": ["aws.backup"],
  "detail-type": ["Backup Job State Change", "Copy Job State Change"],
  "detail": {
    "state": ["FAILED", "COMPLETED"]
  }
}
PATTERN
        },
        {
          name    = "disabled_key_rotation"
          pattern = <<PATTERN
{
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["kms.amazonaws.com"],
    "eventName": ["DisableKeyRotation"]
  }
}
PATTERN
        }

      ]
    }
  }
  providers = {
    aws = aws.workload
  }
}


module "event_sender2" {
  source = "../../member/terraform"

  member_settings = {
    event_collector = {
      central_eventbus_arn = module.central_collector.eventbus_arn
    }
    account_baseline = {
      eb_forwarding_iam_role = {
        name = local.eb_forwarding_iam_role_name
      }
      event_rules = [
        {
          name    = "console_logins"
          pattern = <<PATTERN
{
  "source": ["aws.signin", "aws.sso"],
  "detail-type": ["AWS Console Sign In via CloudTrail", "AWS Single Sign-On Login"],
  "detail": {
    "eventName": ["ConsoleLogin", "AWSConsoleSignIn"],
    "userIdentity": {
      "type": ["IAMUser", "AssumedRole", "Root", "AWSAccount"]
    }
  }
}
PATTERN
        }
      ]
    }
  }
  is_primary_region = false
  providers = {
    aws = aws.workload_use1
  }
}


module "event_sender_cf" {
  source = "../../member/stacksets"

  member_settings = {
    event_collector = {
      central_eventbus_arn = module.central_collector.eventbus_arn
    }
    account_baseline = {
      eb_forwarding_iam_role = {
        name = local.eb_forwarding_iam_role_name
      }
      event_rules = [
        {
          name    = "failed_aws_backups"
          pattern = <<PATTERN
        source:
          - "aws.backup"
        detail-type:
          - "Backup Job State Change"
          - "Copy Job State Change"
        detail:
          state:
            - "FAILED"
PATTERN
        },
        {
          name    = "disable_key_rotation"
          pattern = <<PATTERN
        detail-type:
          - "AWS API Call via CloudTrail"
        detail:
          eventSource:
            - "kms.amazonaws.com"
          eventName:
            - "DisableKeyRotation"
PATTERN
        }

      ]
    }
  }
}