# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  # This module is only being tested with Terraform 1.0 and newer.
  required_version = ">= 1.0.0"

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
      "module_lambda_provider" = "ACAI GmbH",
      "module_name"            = "terraform-aws-acf-event-collector",
      "module_source"          = "github.com/acai-consulting/terraform-aws-acf-event-collector",
      "module_version"         = /*inject_version_start*/ "1.0.0" /*inject_version_end*/
    }
  )
  forwardings = flatten([
    for setting in var.settings : [
      for forwarding in setting.forwardings : {
        eventbus_name = setting.eventbus_name
        cw_lg         = forwarding.cw_lg
      }
    ]
  ])
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ MAIN
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_event_bus" "collector" {
  name = var.settings.eventbus_name
  tags = local.resource_tags  
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
      values   = ["${data.aws_organizations_organization.current.id}"]
    }
  }
}

resource "aws_cloudwatch_event_bus_policy" "central_bus_policy_attach" {
  policy         = data.aws_iam_policy_document.central_bus_policy.json
  event_bus_name = aws_cloudwatch_event_bus.collector.name
}


module "cw_lg_forwarding" {
  for_each = { for fw in local.forwardings : "${fw.eventbus_name}-${fw.cw_lg.lg_name}" => fw }

  source              = "./modules/forward-to-cw-lg"
  settings = {
    eventbus_name = each.value.eventbus_name
    cw_lg         = each.value.cw_lg
  }
  resource_tags = var.resource_tags
}