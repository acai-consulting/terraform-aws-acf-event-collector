output "member_configure_iam_role_name" {
  value = aws_iam_role.member_configure.name
}

output "member_configure_iam_role_arn" {
  value = aws_iam_role.member_configure.arn
}

output "member_event_bus_iam_role_name" {
  value = aws_iam_role.member_event_bus.name
}

output "member_event_bus_iam_role_arn" {
  value = aws_iam_role.member_event_bus.arn
}

