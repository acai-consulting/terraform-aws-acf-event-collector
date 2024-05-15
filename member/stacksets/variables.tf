variable "member_settings" {
  description = "Specification of the member resources"

  type = object({
    event_collector = object({
      central_eventbus_arn = optional(string, "")
    })
    account_baseline = object({
      central_eventbus_iam_role_name = string
      event_patterns                 = list(string)
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

variable "member_resource_tags" {
  description = "A map of tags to assign to the resources in this module."
  type        = map(string)
  default     = {}
}
