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
      var.member_resource_tags,
      {
        "module_provider" = "ACAI GmbH",
        "module_name"     = "terraform-aws-acf-event-collector",
        "module_source"   = "github.com/acai-consulting/terraform-aws-acf-event-collector",
        "module_version"  = /*inject_version_start*/ "1.0.0" /*inject_version_end*/
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
    central_eventbus_arn           = var.member_settings.event_collector.central_eventbus_arn
    central_eventbus_iam_role_name = var.member_settings.account_baseline.central_eventbus_iam_role_name
    resource_tags_block            = local.resource_tags_block
  }
}

data "template_file" "member_regional" {
  template = file("${path.module}/cloudformation/member_regional.yaml.tftpl")
  vars = {
    central_eventbus_arn           = var.member_settings.event_collector.central_eventbus_arn
    central_eventbus_iam_role_name = var.member_settings.account_baseline.central_eventbus_iam_role_name
    
    resource_tags_block            = local.resource_tags_block
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
