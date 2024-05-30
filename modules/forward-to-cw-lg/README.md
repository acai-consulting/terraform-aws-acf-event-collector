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
| <a name="module_cw_lg_events_dump_encryption"></a> [cw\_lg\_events\_dump\_encryption](#module\_cw\_lg\_events\_dump\_encryption) | ../kms | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.forward_to_cw_lg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.forward_to_cw_lg_multiple](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.forward_to_cw_lg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.forward_to_cw_lg_multiple](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.cw_lg_events_dump](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_resource_policy.cw_lg_events_dump_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_resource_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.cw_lg_events_dump_encryption_cmk_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cw_lg_events_dump_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_settings"></a> [settings](#input\_settings) | Settings for the target CW\_LG. | <pre>object({<br>    eventbus_name = string<br>    cw_lg = object({<br>      event_pattern = string<br>      event_patterns = list(object({<br>        pattern_name = string<br>        pattern      = string<br>      }))<br>      lg_name              = string<br>      lg_retention_in_days = number<br>      lg_skip_destroy      = bool<br>      lg_encyrption = object({<br>        cmk_policy_override = list(string) # should override the statement_id 'ReadPermissions'<br>      })<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_resource_tags"></a> [resource\_tags](#input\_resource\_tags) | A map of tags to assign to the resources in this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cw_lg_arn"></a> [cw\_lg\_arn](#output\_cw\_lg\_arn) | CloudWatch LogGroup ARN |
| <a name="output_kms_cmk"></a> [kms\_cmk](#output\_kms\_cmk) | KMS CMK |
<!-- END_TF_DOCS -->