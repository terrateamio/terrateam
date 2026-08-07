variable "compartment_id" {
  type        = string
  description = "Compartment OCID where the bastion will be created"
}

variable "cluster_id" {
  type        = string
  description = "OKE Cluster OCID (required only for OKE sessions)"
  default     = ""
}

variable "target_subnet_id" {
  type        = string
  description = "Subnet OCID for the bastion target network"
}

variable "bastion_name" {
  type        = string
  description = "Name for the bastion service"
}

variable "ssh_public_keys" {
  type        = map(string)
  description = "Map of username to SSH public key content"
  sensitive   = true
}

variable "bastion_sessions" {
  description = "Map of bastion sessions configuration"
  type = map(object({
    type           = string                          # "oke" or "compute"
    pool_name      = optional(string, "")            # For OKE: exact node pool name
    instance_names = optional(list(string), [])      # For compute: list of instance names
    compartment_id = optional(string, "")            # ✅ Add this line
    time           = number                          # Session TTL in minutes
    active         = bool                            # Whether session configuration is active
    user           = string                          # Username for SSH key lookup
    nodes          = optional(list(string), ["all"]) # For OKE: node selection ["all"], ["0", "1"], or ["node-name"]
    os_user        = optional(string, "opc")         # OS username for SSH connection
    port           = optional(number, 22)            # SSH port
  }))

  validation {
    condition = alltrue([
      for session in var.bastion_sessions :
      contains(["oke", "compute"], session.type)
    ])
    error_message = "Session type must be either 'oke' or 'compute'."
  }

  validation {
    condition = alltrue([
      for session in var.bastion_sessions :
      (session.type == "oke" && session.pool_name != "") ||
      (session.type == "compute" && length(session.instance_names) > 0)
    ])
    error_message = "For OKE sessions, pool_name must be specified. For compute sessions, instance_names must be provided."
  }

  validation {
    condition = alltrue([
      for session in var.bastion_sessions :
      session.time > 0 && session.time <= 180
    ])
    error_message = "Session time must be between 1 and 180 minutes."
  }
}


variable "tenancy_ocid" {
  type        = string
  description = "OCI Tenancy OCID"
}

variable "allowed_ips" {
  type        = list(string)
  description = "List of allowed IP CIDR blocks for bastion access"
  default     = ["10.0.0.0/8", "172.16.0.0/12"]

  validation {
    condition = alltrue([
      for ip in var.allowed_ips :
      can(cidrhost(ip, 0))
    ])
    error_message = "All allowed_ips must be valid CIDR blocks."
  }
}

variable "max_session_ttl_seconds" {
  type        = number
  description = "Maximum session TTL in seconds for the bastion"
  default     = 7200

  validation {
    condition     = var.max_session_ttl_seconds >= 1800 && var.max_session_ttl_seconds <= 10800
    error_message = "max_session_ttl_seconds must be between 1800 (30 min) and 10800 (3 hours)."
  }
}
