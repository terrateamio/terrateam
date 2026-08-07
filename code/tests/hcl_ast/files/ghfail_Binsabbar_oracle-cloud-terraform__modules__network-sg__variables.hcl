variable "vcn_id" {
  type        = string
  description = "the ocid of virtual coud network"
}

variable "compartment_id" {
  type        = string
  description = "the ocid of compartment"
}

variable "network_security_groups" {
  type = map(map(object({
    direction     = string
    protocol      = string
    ports         = object({ min : number, max : number })
    type          = optional(string, "CIDR_BLOCK")
    ips           = optional(set(string), [])
    nsg_ids       = optional(set(string), [])
    service_cidrs = optional(set(string), [])
  })))

  default = {}

  validation {
    condition = alltrue([
      for group_name, group in var.network_security_groups :
      alltrue([
        for rule_name, rule in group :
        (rule.type == "CIDR_BLOCK" && length(rule.ips) > 0 && length(rule.nsg_ids) == 0 && length(rule.service_cidrs) == 0) ||
        (rule.type == "SERVICE_CIDR_BLOCK" && length(rule.service_cidrs) > 0 && length(rule.ips) == 0 && length(rule.nsg_ids) == 0) ||
        (rule.type == "NETWORK_SECURITY_GROUP" && length(rule.nsg_ids) > 0 && length(rule.ips) == 0 && length(rule.service_cidrs) == 0)
      ])
    ])
    error_message = <<EOF
    if type is "CIDR_BLOCK" then `ips` must be set, and `nsg_ids` and `service_cidrs` should not be set,
if type is "SERVICE_CIDR_BLOCK" then `service_cidrs` must be set and `nsg_ids` and `ips` is should not be set,
if type is "NETWORK_SECURITY_GROUP" then `nsg_ids` must be set and `service_cidrs` and `ips` is should not be set
    EOF
  }

  validation {
    condition = alltrue([
      for group_name, group in var.network_security_groups :
      alltrue([
        for rule_name, rule in group : rule.direction == "INGRESS" || rule.direction == "EGRESS"
      ])
    ])
    error_message = <<EOF
    The value of direction must be one of the following:
    - "INGRESS"
    - "EGRESS"
    EOF
  }
  description = <<EOL
    map of network security groups, where the key is used as name of the group, and value is a rule configuration
    Rule Configuration
    direction: INGRESS or EGRESS
    protocol : tcp or udp
    ports    : port object that contain the port ranege. Set both min and max to the same value if no range is needed
        min: lower port bound 
        max: upper port bound
    type (optional)          : the type of the nsg rule, default is `CIDR_BLOCK`
    ips  (optional)          : list of IP addresses for the rule. Set if type is `CIDR_BLOCK`
    nsg_ids (optional)       : list of network security group ids for the rule. Set if type is `NETWORK_SECURITY_GROUP`
    service_cidrs (optional) : list of service cidr blocks for the rule. Set if type is `SERVICE_CIDR_BLOCK`
  EOL
}
