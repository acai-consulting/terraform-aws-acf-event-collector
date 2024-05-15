output "eventbus_arn" {
  description = "eventbus_arn"
  value       = aws_cloudwatch_event_bus.collector.arn
}
