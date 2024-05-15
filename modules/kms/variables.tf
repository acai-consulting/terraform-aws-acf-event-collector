variable "cmk_settings" {
  description = "Settings for the target CW_LG."
  type = object({
    alias = optional(string, null)
    description = string
    deletion_window_in_days = optional(number, 30)
    policy_read_override = optional(list(string), null) # should override the statement_id 'ReadPermissions'
    policy_management_override = optional(list(string), null) # should override the statement_id 'ManagementPermissions'
    policy_consumers = list(string)
  })
}

variable "resource_tags" {
  description = "A map of tags to assign to the resources in this module."
  type        = map(string)
  default     = {}
}
