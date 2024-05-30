variable "settings" {
  description = "Settings for the central event collector."
  type = object({
    central_eventbus = object({
      name = string
      encryption = optional(object({
        cmk_policy_override = optional(list(string), null) # should override the statement_ids 'ReadPermissions' or 'ManagementPermissions'
      }), null)
    })
    forwardings = object({
      cw_lg = optional(list(object({
        event_pattern        = optional(string, "{ \"source\": [ { \"prefix\": \"\" } ] }")
        event_patterns       = optional(list(object({
          pattern_name = string
          pattern      = string
        })), [])
        lg_name              = string
        lg_retention_in_days = optional(number, 30)
        lg_skip_destroy      = optional(bool, false)
        lg_encryption = optional(object({
          cmk_policy_override = optional(list(string), []) # should override the statement_ids 'ReadPermissions' or 'ManagementPermissions'
        }), null)
      })), [])
    })
  })
  validation {
    condition = can(
      flatten([
        for f in var.settings.forwardings.cw_lg : (
          (f.event_pattern != null && f.event_patterns == null) ||
          (f.event_pattern == null && f.event_patterns != null) ||
          (f.event_pattern == null && f.event_patterns == null)
        )
      ])[*]
    )
    error_message = "Either 'event_pattern' or 'event_patterns' must be set, but not both."
  }
}


variable "resource_tags" {
  description = "A map of tags to assign to the resources in this module."
  type        = map(string)
  default     = {}
}
