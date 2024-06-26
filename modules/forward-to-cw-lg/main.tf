# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ FORWARDING EVENTS BASED ON PATTERNS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "forward_to_cw_lg" {
  count = var.settings.cw_lg.event_pattern != null ? 1 : 0

  name           = "forward_to_cw_lg_${var.settings.cw_lg.lg_name}"
  event_bus_name = var.settings.eventbus_name
  event_pattern  = var.settings.cw_lg.event_pattern
}

resource "aws_cloudwatch_event_target" "forward_to_cw_lg" {
  count = var.settings.cw_lg.event_pattern != null ? 1 : 0

  target_id      = "SendToCwLg"
  rule           = aws_cloudwatch_event_rule.forward_to_cw_lg[count.index].name
  event_bus_name = var.settings.eventbus_name
  arn            = aws_cloudwatch_log_group.cw_lg_events_dump.arn
}

resource "aws_cloudwatch_event_rule" "forward_to_cw_lg_multiple" {
  count = var.settings.cw_lg.event_patterns != null && length(var.settings.cw_lg.event_patterns) > 0 ? length(var.settings.cw_lg.event_patterns) : 0

  name           = "forward_to_cw_lg_${var.settings.cw_lg.event_patterns[count.index].pattern_name}_${var.settings.cw_lg.lg_name}"
  event_bus_name = var.settings.eventbus_name
  event_pattern  = var.settings.cw_lg.event_patterns[count.index].pattern
}

resource "aws_cloudwatch_event_target" "forward_to_cw_lg_multiple" {
  count = var.settings.cw_lg.event_patterns != null && length(var.settings.cw_lg.event_patterns) > 0 ? length(var.settings.cw_lg.event_patterns) : 0

  target_id      = "SendToCwLg_${var.settings.cw_lg.event_patterns[count.index].pattern_name}"
  rule           = aws_cloudwatch_event_rule.forward_to_cw_lg_multiple[count.index].name
  event_bus_name = var.settings.eventbus_name
  arn            = aws_cloudwatch_log_group.cw_lg_events_dump.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ AWS_CLOUDWATCH_LOG_GROUP
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "cw_lg_events_dump" {
  name              = var.settings.cw_lg.lg_name
  skip_destroy      = var.settings.cw_lg.lg_skip_destroy
  retention_in_days = var.settings.cw_lg.lg_retention_in_days
  kms_key_id        = var.settings.cw_lg.lg_encyrption != null ? module.cw_lg_events_dump_encryption[0].kms_cmk_arn : null
  tags              = var.resource_tags
  depends_on        = [module.cw_lg_events_dump_encryption]
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
module "cw_lg_events_dump_encryption" {
  # checkov:skip=CKV_AWS_109
  # checkov:skip=CKV_AWS_111
  # checkov:skip=CKV_AWS_356
  source = "../kms"
  count  = var.settings.cw_lg.lg_encyrption != null ? 1 : 0

  cmk_settings = {
    alias           = "cmk-for-cw-lg-${var.settings.cw_lg.lg_name}"
    description     = "This key is used to encrypt the logs of the CloudWatch LogGroup ${var.settings.cw_lg.lg_name}"
    policy_override = var.settings.cw_lg.lg_encyrption.cmk_policy_override
    policy_consumers = [
      data.aws_iam_policy_document.cw_lg_events_dump_encryption_cmk_policy[0].json
    ]
  }
}

data "aws_iam_policy_document" "cw_lg_events_dump_encryption_cmk_policy" {
  count = var.settings.cw_lg.lg_encyrption != null ? 1 : 0

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
