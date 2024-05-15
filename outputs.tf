output "eventbus_arn" {
  description = "eventbus_arn"
  value       = aws_cloudwatch_event_bus.collector.arn
}


output "configuration_to_write" {
  description = "HCL map to be stored in configuration map"
  value = {
    central_eventbus_arn = aws_cloudwatch_event_bus.collector.arn
  } 
}

