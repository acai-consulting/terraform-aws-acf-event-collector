# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  # This module is only being tested with Terraform 1.0 and newer.
  required_version = ">= 1.3.10"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.00"
      configuration_aliases = []
    }
  }
}

locals {
  resource_tags_block = templatefile("${path.module}/cloudformation/tags.yaml.tftpl", {
    map_of_tags = merge(
      var.resource_tags,
      {
        "module_provider" = "ACAI GmbH",
        "module_name"     = "terraform-aws-acf-event-collector",
        "module_source"   = "github.com/acai-consulting/terraform-aws-acf-event-collector",
        "module_version"  = /*inject_version_start*/ "1.2.0" /*inject_version_end*/
      }
    )
  })
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CF SPECIFICATION
# ---------------------------------------------------------------------------------------------------------------------
data "template_file" "member_global" {
  template = file("${path.module}/cloudformation/member_global.yaml.tftpl")
  vars = {
    central_eventbus_arn                               = var.settings.event_collector.central_eventbus_arn
    central_eventbus_iam_role_name                     = var.settings.sender.eb_forwarding_iam_role.name
    central_eventbus_iam_role_path                     = var.settings.sender.eb_forwarding_iam_role.path
    central_eventbus_iam_role_permissions_boundary_arn = var.settings.sender.eb_forwarding_iam_role.permissions_boundary_arn
    resource_tags_block                                = local.resource_tags_block
  }
}

data "template_file" "member_regional" {
  template = file("${path.module}/cloudformation/member_regional.yaml.tftpl")
  vars = {
    central_eventbus_arn           = var.settings.event_collector.central_eventbus_arn
    central_eventbus_iam_role_name = var.settings.sender.eb_forwarding_iam_role.name
    event_rules = jsonencode([
      for rule in var.settings.sender.event_rules : {
        camel_case_name = join("", [
          for part in split("_", replace(rule.name, "-", "_")) : title(part)
        ])
        name           = rule.name
        description    = rule.description
        event_bus_name = rule.event_bus_name
        pattern        = rule.pattern

      }
      ]
    )

    resource_tags_block = local.resource_tags_block
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ COMPILE STACKSETS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  stacksets = [
    {
      stackset_name = var.stackset_name_global
      capabilities = [
        "CAPABILITY_IAM",
        "CAPABILITY_NAMED_IAM"
      ]
      template_body = data.template_file.member_global.rendered
    },
    {
      stackset_name = var.stackset_name_regional
      template_body = data.template_file.member_regional.rendered
    }
  ]
}
