output "cw_lg_arn" {
  description = "CloudWatch LogGroup ARN"
  value       = aws_cloudwatch_log_group.cw_lg_events_dump.arn
}

output "kms_cmk" {
  description = "KMS CMK"
  value       = var.settings.cw_lg.lg_encyrption != null ? module.cw_lg_events_dump_encryption[0] : null

}