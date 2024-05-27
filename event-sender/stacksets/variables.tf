variable "settings" {
  description = "Specification of the member resources"
  type = object({
    event_collector = object({
      central_eventbus_arn = optional(string, "")
    })
    sender = object({
      eb_forwarding_iam_role = object({
        name                     = optional(string, "event-collector-forwarder-role")
        path                     = optional(string, "/")
        permissions_boundary_arn = optional(string, "")
      })
      event_rules = list(object({
        name           = string
        description    = optional(string, "")
        event_bus_name = optional(string, "default")
        pattern        = string
      }))
    })
  })
}

variable "stackset_name_global" {
  description = "Name of the StackSet"
  type        = string
  default     = "account-baseline--event-collector-global"
}

variable "stackset_name_regional" {
  description = "Name of the StackSet"
  type        = string
  default     = "account-baseline--event-collector-regional"
}

variable "resource_tags" {
  description = "A map of tags to assign to the resources in this module."
  type        = map(string)
  default     = {}
}
