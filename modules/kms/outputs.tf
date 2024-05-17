output "kms_cmk_arn" {
  description = "Key ARN"
  value       = aws_kms_key.kms_cmk.arn
}

output "kms_cmk_policy" {
  description = "Key Policy"
  value       = aws_kms_key.kms_cmk.policy
}