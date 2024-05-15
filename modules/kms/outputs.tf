output "kms_cmk_id" {
  description = "Key ID"
  value       = aws_kms_key.kms_cmk.id
}

output "kms_cmk_policy" {
  description = "Key Policy"
  value       = aws_kms_key.kms_cmk.policy
}