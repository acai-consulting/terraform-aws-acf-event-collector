# terraform-aws-acf-event-collector Terraform module

<!-- LOGO -->
<a href="https://acai.gmbh">    
  <img src="https://github.com/acai-consulting/acai.public/raw/main/logo/logo_github_readme.png" alt="acai logo" title="ACAI" align="right" height="75" />
</a>

<!-- SHIELDS -->
[![Maintained by acai.gmbh][acai-shield]][acai-url]
![module-version-shield]
![terraform-version-shield]
![trivy-shield]
![checkov-shield]
[![Latest Release][release-shield]][release-url]

<!-- DESCRIPTION -->
[Terraform][terraform-url] module to deploy a central [Amazon EventBridge Event Bus](https://docs.aws.amazon.com/de_de/eventbridge/latest/userguide/eb-event-bus.html) and decentral Amazon EventBridge rules, sending to the central Amazon EventBridge Event Bus.

<!-- ARCHITECTURE -->
## Architecture
![architecture][architecture-url]

<!-- USAGE -->
## Usage

### Central Amazon EventBridge Event Bus

```hcl
module "central_collector" {
  source = "./"

  settings = {
    eventbus_name = "central_eventbus"
    forwardings = {
      cw_lg = [
        {
          lg_name = "central_events"
        }
      ]
    }
  }
  providers = {
    aws = aws.core_security
  }
}
```

### Decentral Amazon EventBridge EventRules

```hcl
module "event_sender1" {
  source = "./member/terraform"

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
          name = "failed_aws_backups"
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
          name = "disabled_key_rotation"
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
```
<!-- EXAMPLES -->
## Examples

* [examples/complete][example-complete-url]

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.10 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cw_lg_forwarding"></a> [cw\_lg\_forwarding](#module\_cw\_lg\_forwarding) | ./modules/forward-to-cw-lg | n/a |
| <a name="module_eventbus_encryption"></a> [eventbus\_encryption](#module\_eventbus\_encryption) | ./modules/kms | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_bus.collector](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_bus) | resource |
| [aws_cloudwatch_event_bus_policy.central_bus_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_bus_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.central_bus_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.eventbus_encryption_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_organizations_organization.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_settings"></a> [settings](#input\_settings) | Settings for the central event collector. | <pre>object({<br>    central_eventbus = object({<br>      name = string<br>      encyrption = optional(object({<br>        cmk_policy_override = optional(list(string), null) # should override the statement_ids 'ReadPermissions' or 'ManagementPermissions'<br>      }), null)<br>    })<br>    forwardings = object({<br>      cw_lg = optional(list(object({<br>        event_pattern        = optional(string, "{ \"source\": [ { \"prefix\": \"\" } ] }")<br>        lg_name              = string<br>        lg_retention_in_days = optional(number, 30)<br>        lg_skip_destroy      = optional(bool, false)<br>        lg_encyrption = optional(object({<br>          cmk_policy_override = optional(list(string), []) # should override the statement_ids 'ReadPermissions' or 'ManagementPermissions'<br>        }), null)<br>      })), [])<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_resource_tags"></a> [resource\_tags](#input\_resource\_tags) | A map of tags to assign to the resources in this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_configuration_to_write"></a> [configuration\_to\_write](#output\_configuration\_to\_write) | HCL map to be stored in configuration map |
| <a name="output_eventbus_arn"></a> [eventbus\_arn](#output\_eventbus\_arn) | eventbus\_arn |
<!-- END_TF_DOCS -->

<!-- AUTHORS -->
## Authors

This module is maintained by [ACAI GmbH][acai-url].

<!-- LICENSE -->
## License

See [LICENSE][license-url] for full details.

<!-- COPYRIGHT -->
<br />
<br />
<p align="center">Copyright &copy; 2024 ACAI GmbH</p>


<!-- MARKDOWN LINKS & IMAGES -->
[acai-shield]: https://img.shields.io/badge/maintained_by-acai.gmbh-CB224B?style=flat
[acai-url]: https://acai.gmbh
[module-version-shield]: https://img.shields.io/badge/module_version-1.1.0-CB224B?style=flat
[terraform-version-shield]: https://img.shields.io/badge/tf-%3E%3D1.3.10-blue.svg?style=flat&color=blueviolet
[trivy-shield]: https://img.shields.io/badge/trivy-passed-green
[checkov-shield]: https://img.shields.io/badge/checkov-passed-green
[release-shield]: https://img.shields.io/github/v/release/acai-consulting/terraform-aws-acf-event-collector?style=flat&color=success
[release-url]: https://github.com/acai-consulting/terraform-aws-acf-event-collector/releases
[license-url]: https://github.com/acai-consulting/terraform-aws-acf-event-collector?tab=License-1-ov-file
[example-complete-url]: https://github.com/acai-consulting/terraform-aws-acf-event-collector/examples/complete
[terraform-url]: https://www.terraform.io
[architecture-url]: ./docs/terraform-aws-acf-event-collector.svg
