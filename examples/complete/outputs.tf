output "account_id" {
  description = "account_id"
  value       = data.aws_caller_identity.core_security.account_id
}

output "central_collector" {
  description = "central_collector"
  value       = module.central_collector
}

output "event_sender1" {
  description = "event_sender1"
  value       = module.event_sender1
}

output "event_sender2" {
  description = "event_sender2"
  value       = module.event_sender2
}

output "event_sender_cf" {
  description = "event_sender_cf"
  value       = module.event_sender_cf
}
