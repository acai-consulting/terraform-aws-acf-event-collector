## Member Accounts
Then the following IAM Roles are required in all member accounts:

> ToDo: Condition to restrict the events and config actions to the resource-name prefix "semper_" will be added later.

###SEMPER EventBridge Cross Account Role
Name: {MemberAccount.Semper_Cross_Account_Access_Role_Name}
Trust Policy:
```json {linenos=table,hl_lines=[],linenostart=50}
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TrustForEventService",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```
Permission Policy:
```json {linenos=table,hl_lines=[],linenostart=50}
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowInvokeEventBus",
            "Effect": "Allow",
            "Action": "events:PutEvents",
            "Resource": "arn:aws:events:{CoreSecurityAccount.Semper_Region_Name}:{CoreSecurityAccount.AccountId}:event-bus/{CoreSecurityAccount.Semper_Processing_InboundEventBus_Name}"
        }
    ]
}
```
  
###SEMPER Member Role
Name: {MemberAccount.Semper_Member_Role_Name}
Trust Policy:
```json {linenos=table,hl_lines=[],linenostart=50}
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TrustPolicy",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::{CoreSecurityAccount.AccountId}:role/{CoreSecurityAccount.Semper_Configure_ExecutionRole_Name}",
          "arn:aws:iam::{CoreSecurityAccount.AccountId}:role/{CoreSecurityAccount.Semper_ConfigEvaluator_ExecutionRole_Name}"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```
Permission Policy:
```json {linenos=table,hl_lines=[],linenostart=50}
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "SEMPER_ConfigurePermissions",
            "Effect": "Allow",
            "Action": [
                "events:PutTargets",
                "events:DeleteRule",
                "iam:PassRole",
                "config:PutConfigRule",
                "events:PutRule",
                "events:RemoveTargets",
                "config:DeleteConfigRule",
                "events:ListTargetsByRule"
            ],
            "Resource": [
                "arn:aws:config:*:{MemberAccount.AccountId}:config-rule/*",
                "arn:aws:iam::{MemberAccount.AccountId}:role/{MemberAccount.Semper_Cross_Account_Access_Role_Name}",
                "arn:aws:events:*:{MemberAccount.AccountId}:rule/*",
                "arn:aws:events:eu-central-1:{MemberAccount.AccountId}:rule/*"
            ]
        },
        {
            "Sid": "SEMPER_AwsConfigEvaluation",
            "Effect": "Allow",
            "Action": "config:PutEvaluations",
            "Resource": "*"
        }
    ]
}
```
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.15.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.15 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.15 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.member_config_evaluator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.member_configure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.member_event_bus](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.member_config_evaluator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.member_configure_aws_config_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.member_configure_eventbridge_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.member_event_bus](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.member_config_evaluator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.member_config_evaluator_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.member_configure_aws_config_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.member_configure_eventbridge_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.member_configure_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.member_event_bus](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.member_event_bus_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_core_security_account_id"></a> [core\_security\_account\_id](#input\_core\_security\_account\_id) | Account-ID of the Core Security account. | `string` | n/a | yes |
| <a name="input_core_security_configure_account_lambda_execution_role_arn"></a> [core\_security\_configure\_account\_lambda\_execution\_role\_arn](#input\_core\_security\_configure\_account\_lambda\_execution\_role\_arn) | ARN of the Core Security role used for the Configure-Account Lambda. | `string` | n/a | yes |
| <a name="input_core_security_processing_inbound_eventbus_arn"></a> [core\_security\_processing\_inbound\_eventbus\_arn](#input\_core\_security\_processing\_inbound\_eventbus\_arn) | ARN of the Security Event collector EventBus provided by the Core Security account. | `string` | n/a | yes |
| <a name="input_member_config_evaluator_iam_role_name"></a> [member\_config\_evaluator\_iam\_role\_name](#input\_member\_config\_evaluator\_iam\_role\_name) | Alphanumeric name of the IAM role assumed from SEMPER Core Security. | `string` | `"semper-member-config-evaluator-role"` | no |
| <a name="input_member_configure_iam_role_name"></a> [member\_configure\_iam\_role\_name](#input\_member\_configure\_iam\_role\_name) | Alphanumeric name of the IAM role assumed from SEMPER Core Security. | `string` | `"semper-member-configure-role"` | no |
| <a name="input_member_configure_resource_prefix"></a> [member\_configure\_resource\_prefix](#input\_member\_configure\_resource\_prefix) | Alphanumeric name of the AWS Config Rules and AWS Event Rules that will be provisioned. Will be used for tailoring the IAM Policy of the SEMPER Member role. | `string` | `"semper"` | no |
| <a name="input_member_eventbus_iam_role_name"></a> [member\_eventbus\_iam\_role\_name](#input\_member\_eventbus\_iam\_role\_name) | Alphanumeric name of the IAM role used for cross account event sharing. | `string` | `"semper-events-cross-account-access-role"` | no |
| <a name="input_member_iam_role_path"></a> [member\_iam\_role\_path](#input\_member\_iam\_role\_path) | Path of the IAM role. | `string` | `null` | no |
| <a name="input_member_iam_role_permissions_boundary_arn"></a> [member\_iam\_role\_permissions\_boundary\_arn](#input\_member\_iam\_role\_permissions\_boundary\_arn) | ARN of the policy that is used to set the permissions boundary for all IAM roles of the module. | `string` | `null` | no |
| <a name="input_member_iam_role_tags"></a> [member\_iam\_role\_tags](#input\_member\_iam\_role\_tags) | A map of tags to assign to the resources in this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_member_config_evaluator_iam_role_arn"></a> [member\_config\_evaluator\_iam\_role\_arn](#output\_member\_config\_evaluator\_iam\_role\_arn) | n/a |
| <a name="output_member_config_evaluator_iam_role_name"></a> [member\_config\_evaluator\_iam\_role\_name](#output\_member\_config\_evaluator\_iam\_role\_name) | n/a |
| <a name="output_member_configure_iam_role_arn"></a> [member\_configure\_iam\_role\_arn](#output\_member\_configure\_iam\_role\_arn) | n/a |
| <a name="output_member_configure_iam_role_name"></a> [member\_configure\_iam\_role\_name](#output\_member\_configure\_iam\_role\_name) | n/a |
| <a name="output_member_event_bus_iam_role_arn"></a> [member\_event\_bus\_iam\_role\_arn](#output\_member\_event\_bus\_iam\_role\_arn) | n/a |
| <a name="output_member_event_bus_iam_role_name"></a> [member\_event\_bus\_iam\_role\_name](#output\_member\_event\_bus\_iam\_role\_name) | n/a |
<!-- END_TF_DOCS -->