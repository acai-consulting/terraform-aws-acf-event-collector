variable "settings" {
  description = "Settings for the target CW_LG."
  type = object({
    eventbus_name = string
    cw_lg = object({
      event_pattern        = optional(string, null)
      lg_name              = string
      lg_retention_in_days = number
      lg_skip_destroy      = optional(bool, false)
      lg_encyrption = optional(object({
        cmk_policy_read_override       = optional(list(string), null) # should override the statement_id 'ReadPermissions'
        cmk_policy_management_override = optional(list(string), null) # should override the statement_id 'ManagementPermissions'
      }), null)
    })
  })
}

variable "resource_tags" {
  description = "A map of tags to assign to the resources in this module."
  type        = map(string)
  default     = {}
}
