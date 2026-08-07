variable "clusters" {
  type = map(object({
    region            = string
    vpc_cidr          = string
    vault_version     = string
    vault_ec2_type    = string
    use_private_image = bool
  }))

  description = "Defines all Vault clusters, map of custom objects"

  validation {
    condition     = alltrue([for version in [for cluster in var.clusters : cluster.vault_version] : can(regex("^([0-9]\\.[0-9]{1,2}?\\.[0-9]{1,2}?\\+ent\\-[0-9])$", version))])
    error_message = "Please, enter correct version of Vault"
  }

  validation {
    condition     = alltrue([for vault_ec2_type in [for cluster in var.clusters : cluster.vault_ec2_type] : can(contains(["small", "large"], vault_ec2_type))])
    error_message = "Please, pick either small or large for vault_ec2_type"
  }

  validation {
    condition = (
      alltrue([for cidr in [for cluster in var.clusters : cluster.vpc_cidr] :
        can(cidrhost(cidr, 0)) &&
        try(cidrhost(cidr, 0), null) == split("/", cidr)[0]
      ])
    )
    error_message = "Please, enter a correct CIDR"
  }

  validation {
    condition     = alltrue([for region in [for cluster in var.clusters : cluster.region] : can(regex("^((af|ap|ca|eu|me|sa|us)-(central|north|(north(?:east|west))|south|south(?:east|west)|east|west)\\-\\d)$", region))])
    error_message = "Please, enter correct AWS region"
  }
}