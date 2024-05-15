# ---------------------------------------------------------------------------------------------------------------------
# ¦ VERSIONS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.10"

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
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ FORWARDING EVENTS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_event_bus_policy" "central_bus_policy_attach" {
  policy         = data.aws_iam_policy_document.central_bus_policy.json
  event_bus_name = var.settings.eventbus_name
}

resource "aws_cloudwatch_event_rule" "forward_to_cw_lg" {
  name           = "forward_to_cw_lg_${var.settings.cw_lg.lg_name}"
  event_bus_name = var.settings.eventbus_name
  event_pattern  = var.settings.cw_lg.event_pattern
}

resource "aws_cloudwatch_event_target" "forward_to_cw_lg" {
  rule      = aws_cloudwatch_event_rule.forward_to_cw_lg.name
  target_id = "SendToCwLg"
  arn       = aws_cloudwatch_log_group.events_dump.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ AWS_CLOUDWATCH_LOG_GROUP
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "cw_lg_events_dump" {
  name              = var.settings.cw_lg.lg_name
  skip_destroy      = var.settings.cw_lg.lg_skip_destroy
  retention_in_days = var.settings.cw_lg.lg_retention_in_days
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn
  tags              = var.resource_tags
}

data "aws_iam_policy_document" "cw_lg_events_dump_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.cw_lg_events_dump.arn}:*"
    ]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "delivery.logs.amazonaws.com"
      ]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "cw_lg_events_dump_policy" {
  policy_document = data.aws_iam_policy_document.cw_lg_events_dump_policy.json
  policy_name     = "${aws_cloudwatch_log_group.cw_lg_events_dump.name}-policy"
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ OPTIONAL ENCRYPTION
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_kms_key" "cw_lg_events_dump_encryption" {
  count = var.settings.cw_lg.lg_encyrption != null ? 1 : 0

  description             = "This key is used to encrypt the logs of the CloudWatch LogGroup ${var.settings.cw_lg.lg_name}"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.cw_lg_events_dump_encryption_cmk_policy[0].json
}

data "aws_iam_policy_document" "cw_lg_events_dump_encryption_cmk_policy" {
  count = var.settings.cw_lg.lg_encyrption != null ? 1 : 0

  #checkov:skip=CKV_AWS_109 : Resource policy
  #checkov:skip=CKV_AWS_111 : Resource policy
  #checkov:skip=CKV_AWS_356 : Resource policy  
  # enable IAM in logging account
  override_policy_documents = var.settings.cw_lg.lg_encyrption.kms_policy_overrides

  statement {
    sid    = "ReadPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
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
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
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
  statement {
    sid    = "ServicePermissions"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${var.settings.cw_lg.lg_name}"]
    }
  }
}

resource "aws_kms_alias" "loggroup_aws_kms_alias" {
  count = var.settings.cw_lg.lg_encyrption != null ? 1 : 0

  name          = "alias/cmk-for-cw-lg-${var.settings.cw_lg.lg_name}"
  target_key_id = aws_kms_key.cw_lg_events_dump_encryption[0].key_id
}
