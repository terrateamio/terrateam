variable "create_vpc" {
  type        = bool
  default     = true
  description = "Shows whether a VCP object should be created. If false, an existing `vpc_id` is required."
}

variable "create_sg" {
  type        = bool
  default     = true
  description = "Shows whether а security group for VCP object should be created"
}

variable "vpc_id" {
  type        = string
  default     = null
  description = "Existing `network_id` (`vpc-id`) where resources will be created"
}

variable "network_name" {
  description = "Prefix to be used with all the resources as an identifier"
  type        = string
}

variable "network_description" {
  description = "Optional description of this resource. Provide this property when you create the resource."
  type        = string
  default     = "terraform-created"
}

variable "folder_id" {
  type        = string
  default     = null
  description = "Folder ID where the resources will be created"
}

variable "public_subnets" {
  description = <<EOF
  "Describe your public subnet preferences. For VMs with public IPs. For Multi-Folder VPC add folder_ids to subnet objects"
  Example:
  public_subnets = [
  {
    "v4_cidr_blocks" : ["10.121.0.0/16", "10.122.0.0/16"],
    "zone" : "ru-central1-a"
    "description" : "Custom public-subnet description"
    "name" : "Custom public-subnet name"
  },
  {
    "v4_cidr_blocks" : ["10.131.0.0/16"],
    "zone" : "ru-central1-b"
    "folder_id" : "xxxxxxx" # For Multi-Folder VPC
  },
  ]
  EOF
  type = list(object({
    v4_cidr_blocks = list(string)
    zone           = string
    description    = optional(string)
    name           = optional(string)
    folder_id      = optional(string)
  }))
  default = []
  validation {
    condition = var.public_subnets == [] || alltrue([
      for subnet in var.public_subnets :
      length(subnet.v4_cidr_blocks) > 0 &&
      alltrue([for cidr in subnet.v4_cidr_blocks : can(cidrnetmask(cidr))])
    ])
    error_message = "All CIDR blocks must be valid IPv4 CIDR notation."
  }
}

variable "private_subnets" {
  description = <<EOF
  "Describe your private subnet preferences. For VMs without public IPs but with or without NAT gateway. For Multi-Folder VPC add folder_id to subnet object"
  private_subnets = [
  {
    "v4_cidr_blocks" : ["10.221.0.0/16"],
    "zone" : "ru-central1-a"
    "description" : "Custom private-subnet description"
    "name" : "Custom private-subnet name"
  },
  {
    "v4_cidr_blocks" : ["10.231.0.0/16"],
    "zone" : "ru-central1-b"
    "folder_id" : "xxxxxxx" # For Multi-Folder VPC
  },
  ]
  EOF
  type = list(object({
    v4_cidr_blocks = list(string)
    zone           = string
    description    = optional(string)
    name           = optional(string)
    folder_id      = optional(string)
  }))
  default = []
  validation {
    condition = var.private_subnets == [] || alltrue([
      for subnet in var.private_subnets :
      length(subnet.v4_cidr_blocks) > 0 &&
      alltrue([for cidr in subnet.v4_cidr_blocks : can(cidrnetmask(cidr))])
    ])
    error_message = "All CIDR blocks must be valid IPv4 CIDR notation."
  }
}

variable "create_nat_gw" {
  description = "Create a NAT gateway for internet access from private subnets"
  type        = bool
  default     = true
}

variable "routes_public_subnets" {
  description = "Describe your route preferences for public subnets"
  type = list(object({
    destination_prefix = string
    next_hop_address   = string
  }))
  default = null
}
variable "routes_private_subnets" {
  description = "Describe your route preferences for public subnets"
  type = list(object({
    destination_prefix = string
    next_hop_address   = string
  }))
  default = null
}
variable "domain_name" {
  type        = string
  default     = "internal."
  description = "Domain name to be added to DHCP options"
}

variable "domain_name_servers" {
  type        = list(string)
  default     = []
  description = "Domain name servers to be added to DHCP options. Only ip addresses can be used"
}
variable "ntp_servers" {
  type        = list(string)
  default     = []
  description = "NTP Servers for subnets. Only ip addresses can be used"
}
variable "labels" {
  description = "Set of key/value label pairs to assign."
  type        = map(string)
  default = {
    created_by = "terraform-yc-module"
  }
}
variable "s3_private_endpoint" {
  type = object({
    enable                      = optional(bool, false)
    private_dns_records_enabled = optional(bool, true)
    subnet_v4_cidr_block        = optional(string, null)
    address                     = optional(string, null)
    }
  )
  default     = {}
  description = "Configuration for creating a private endpoint for Yandex Object Storage. When enabled, creates a secure connection to Object Storage without going through the public internet. Specify a subnet CIDR block and an IP address for the endpoint from one of the 'privite subnet's CIDR block'. At least one private subnet must be defined when s3_private_endpoint is enabled."
}
