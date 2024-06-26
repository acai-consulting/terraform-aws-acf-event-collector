# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.00"
    }
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  resource_tags = merge(
    var.resource_tags,
    {
      "module_provider" = "ACAI GmbH",
      "module_name"     = "terraform-aws-acf-event-collector",
      "module_source"   = "github.com/acai-consulting/terraform-aws-acf-event-collector",
      "module_version"  = /*inject_version_start*/ "1.2.0" /*inject_version_end*/
    }
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ IAM ROLE TO PUBLIS TO CENTRAL EVENTBUS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "eventbus_forwarder" {
  count = var.is_primary_region == true ? 1 : 0

  name                 = var.settings.sender.eb_forwarding_iam_role.name
  path                 = var.settings.sender.eb_forwarding_iam_role.path
  permissions_boundary = var.settings.sender.eb_forwarding_iam_role.permissions_boundary_arn
  assume_role_policy   = data.aws_iam_policy_document.eventbus_forwarder_trust.json
  tags                 = local.resource_tags
}

// allow only aws serice Lambda to assume the role
data "aws_iam_policy_document" "eventbus_forwarder_trust" {
  statement {
    sid    = "TrustPolicy"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role_policy" "eventbus_forwarder_permissions" {
  count = var.is_primary_region == true ? 1 : 0

  name   = "EventBusPermissions"
  role   = aws_iam_role.eventbus_forwarder[0].name
  policy = data.aws_iam_policy_document.eventbus_forwarder_permissions[0].json
}

#AWS Config does not allow restrictions to resource name prefixes
#tfsec:ignore:AVD-AWS-0057
data "aws_iam_policy_document" "eventbus_forwarder_permissions" {
  count = var.is_primary_region == true ? 1 : 0

  #checkov:skip=CKV_AWS_111 : SEMPER Config Rules cannot be selected for restriction
  #checkov:skip=CKV_AWS_356 : SEMPER Config Rules cannot be selected for restriction
  statement {
    sid    = "AllowPutEventToCentralEventBus"
    effect = "Allow"
    actions = [
      "events:PutEvents"
    ]
    resources = [var.settings.event_collector.central_eventbus_arn]
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ EVENTBUS CROSS ACCOUNT IAM ROLE 
#   Allow event-bus from other account to send to Core Auditing Account 
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "eventsrule_cloudwatch" {
  count = length(var.settings.sender.event_rules)

  name           = element(var.settings.sender.event_rules, count.index).name
  description    = element(var.settings.sender.event_rules, count.index).description
  event_bus_name = element(var.settings.sender.event_rules, count.index).event_bus_name
  event_pattern  = element(var.settings.sender.event_rules, count.index).pattern
  tags           = local.resource_tags
}

resource "aws_cloudwatch_event_target" "forward_to_central_eb" {
  count = length(var.settings.sender.event_rules)

  target_id = "SendtoCentralEventBus"
  role_arn  = replace("arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.settings.sender.eb_forwarding_iam_role.path}${var.settings.sender.eb_forwarding_iam_role.name}", "////", "/")
  rule      = element(aws_cloudwatch_event_rule.eventsrule_cloudwatch.*.name, count.index)
  arn       = var.settings.event_collector.central_eventbus_arn
}
