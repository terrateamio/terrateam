
variable "name" {
  description = "An alphanumeric string up to 64 characters long."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_.:-]{0,64}$", var.name))
    error_message = "The name must be alphanumeric and up to 64 characters."

  }
}

variable "vxlan_site_id" {
  description = "A site ID integer up to 65535."
  type        = number
  validation {
    condition     = var.vxlan_site_id >= 1 && var.vxlan_site_id <= 65535 && floor(var.vxlan_site_id) == var.vxlan_site_id
    error_message = "The site_id must be an integer between 1 and 65535."
  }
}

variable "external_data_plane_ips" {
  description = "A list of external data plane IPs, each with a pod_id (1-254) and an IPv4 address."
  type = list(object({
    pod_id = number
    ip     = string
  }))
  validation {
    condition = alltrue([
      for item in var.external_data_plane_ips :
      item.pod_id >= 1 && item.pod_id <= 254 &&
      can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", item.ip))
    ])
    error_message = "Each item must have pod_id (1-254) and a valid IPv4 address (no netmask)."
  }
}
