variable "settings" {
  description = "Settings for the central event collector."
  type = list(object({
    eventbus_name = string
    forwardings = list(object({
      cw_lg = list(object({
        lg_name = string
        event_pattern = optional(string, null)
      }))
    }))
  }))
}

variable "resource_tags" {
  description = "A map of tags to assign to the resources in this module."
  type        = map(string)
  default     = {}
}
