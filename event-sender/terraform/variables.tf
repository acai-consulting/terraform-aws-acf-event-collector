variable "settings" {
  description = "Specification of the sender resources"
  type = object({
    event_collector = object({
      central_eventbus_arn = optional(string, "")
    })
    sender = object({
      eb_forwarding_iam_role = object({
        name                     = optional(string, "event-collector-forwarder-role")
        path                     = optional(string, "/")
        permissions_boundary_arn = optional(string, null)
      })
      event_rules = list(object({
        name           = string
        description    = optional(string, null)
        event_bus_name = optional(string, "default")
        pattern        = string
      }))
    })
  })
}

variable "is_primary_region" {
  description = "For provisioning global resources only one time."
  type        = bool
  default     = true
}


variable "resource_tags" {
  description = "A map of tags to assign to the resources in this module."
  type        = map(string)
  default     = {}
}
