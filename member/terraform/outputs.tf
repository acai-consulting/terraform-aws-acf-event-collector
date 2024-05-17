output "eventbus_forwarder_iam_role_name" {
  value = var.member_settings.account_baseline.eb_forwarding_iam_role.name
}

output "eventbus_forwarder_iam_role_arn" {
  value = var.is_primary_region == true ? aws_iam_role.eventbus_forwarder[0].arn : null
}

output "event_rules" {
  value = aws_cloudwatch_event_rule.eventsrule_cloudwatch
}
