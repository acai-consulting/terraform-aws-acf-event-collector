variable "settings" {
  description = "Settings for the central event collector."
  type = object({
    eventbus_name = string
    eventbus_encyrption = optional(object({
      kms_policy_overrides = optional(list(string), null) # should override the statement_id 'PrincipalPermissions'
    }), null)
    forwardings = object({
      cw_lg = optional(list(object({
        event_pattern        = optional(string, "{ \"source\": [\"aws.events\"] }")
        lg_name              = string
        lg_retention_in_days = optional(number, 30)
        lg_skip_destroy      = optional(bool, false)
        lg_encyrption = optional(object({
          kms_policy_overrides = optional(list(string), null) # here you can override the statement_ids 'ReadPermissions' or 'ManagementPermissions'
        }), null)
      })), [])
    })
  })
}

variable "resource_tags" {
  description = "A map of tags to assign to the resources in this module."
  type        = map(string)
  default     = {}
}
