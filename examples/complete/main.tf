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
# ¦ TEST DATA
# ---------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "override" {
  statement {
    sid    = "ReadPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.core_logging.account_id}:root"]
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
module "example_complete" {
  source = "../../"

  settings = {
    eventbus_name = "test"
    eventbus_encyrption = {
      cmk_policy_override = [
        data.aws_iam_policy_document.override.json
      ]
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
