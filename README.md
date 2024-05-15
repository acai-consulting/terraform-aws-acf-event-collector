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
[Terraform][terraform-url] module to deploy a central [Amazon EventBridge Event Bus](https://docs.aws.amazon.com/de_de/eventbridge/latest/userguide/eb-event-bus.html) and decentral Amazon EventBridge rules sending to the centralAmazon EventBridge Event Bus.

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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | account\_id |
| <a name="output_input"></a> [input](#output\_input) | pass through input |
<!-- END_TF_DOCS -->

<!-- AUTHORS -->
## Authors

This module is maintained by [ACAI GmbH][acai-url] with help from [these amazing contributors][contributors-url]

<!-- LICENSE -->
## License

This module is licensed under Apache 2.0
<br />
See [LICENSE][license-url] for full details

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
[license-url]: https://github.com/acai-consulting/terraform-aws-acf-event-collector/tree/main/LICENSE.md
[example-complete-url]: https://github.com/acai-consulting/terraform-aws-acf-event-collector/examples/complete
[terraform-url]: https://www.terraform.io
[architecture-url]: ./docs/terraform-aws-acf-event-collector.svg
