variable "settings" {
  description = "Settings for the target CW_LG."
  type = object({
    eventbus_name = string
    cw_lg = object({
      event_pattern = string
      event_patterns = list(object({
        pattern_name = string
        pattern      = string
      }))
      lg_name              = string
      lg_retention_in_days = number
      lg_skip_destroy      = bool
      lg_encyrption = object({
        cmk_policy_override = list(string) # should override the statement_id 'ReadPermissions'
      })
    })
  })
}

variable "resource_tags" {
  description = "A map of tags to assign to the resources in this module."
  type        = map(string)
  default     = {}
}
