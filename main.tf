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
data "aws_organizations_organization" "current" {}

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
      "module_version"  = /*inject_version_start*/ "1.0.0" /*inject_version_end*/
    }
  )
  cw_lg_forwardings = flatten([
    for cw_lg_forwarding in var.settings.forwardings.cw_lg : {
      eventbus_name = var.settings.eventbus_name
      cw_lg         = cw_lg_forwarding
    }
  ])
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ MAIN
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_event_bus" "collector" {
  name = var.settings.eventbus_name
  tags = local.resource_tags
  #TODO: add KMS CMK ARN as soon as AWS Provider supports this
}

data "aws_iam_policy_document" "central_bus_policy" {
  statement {
    sid    = "AllowAllAccountsFromOrganizationToPutEvents"
    effect = "Allow"
    actions = [
      "events:PutEvents"
    ]
    resources = [
      "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:event-bus/${aws_cloudwatch_event_bus.collector.name}",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [ data.aws_organizations_organization.current.id ]
    }
  }
}

resource "aws_cloudwatch_event_bus_policy" "central_bus_policy_attach" {
  policy         = data.aws_iam_policy_document.central_bus_policy.json
  event_bus_name = aws_cloudwatch_event_bus.collector.name
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ OPTIONAL ENCRYPTION
# https://aws.amazon.com/de/about-aws/whats-new/2024/05/amazon-eventbridge-cmk-event-buses/
# ---------------------------------------------------------------------------------------------------------------------
module "eventbus_encryption" {
  source = "./modules/kms"
  count  = var.settings.eventbus_encyrption != null ? 1 : 0

  cmk_settings = {
    alias           = "cmk-for-eventbus-${var.settings.eventbus_name}"
    description     = "This key is used to encrypt the Events in the Eventbus ${var.settings.eventbus_name}"
    policy_override = var.settings.eventbus_encyrption.cmk_policy_override
    policy_consumers = [
      data.aws_iam_policy_document.eventbus_encryption_policy[0].json
    ]
  }
}

data "aws_iam_policy_document" "eventbus_encryption_policy" {
  count = var.settings.eventbus_encyrption != null ? 1 : 0

  statement {
    sid    = "ServicePermissions"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:event-bus/${var.settings.eventbus_name}"]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ FORWARDING TO ClOUDWATCH LOGGROUP
# ---------------------------------------------------------------------------------------------------------------------
module "cw_lg_forwarding" {
  for_each = { for fw in local.cw_lg_forwardings : "${fw.eventbus_name}-${fw.cw_lg.lg_name}" => fw }

  source = "./modules/forward-to-cw-lg"
  settings = {
    eventbus_name = each.value.eventbus_name
    cw_lg         = each.value.cw_lg
  }
  resource_tags = var.resource_tags
}

