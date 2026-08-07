###############################################################################
# EFS CSI Driver Variables
###############################################################################
variable "region" {
  type        = string
  description = "AWS region where the EFS file system will be created."

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-east-1, eu-west-1, ap-southeast-2)."
  }
}

variable "env" {
  type        = string
  description = "Environment for the EFS CSI driver (dev, sta, pro, tes)."

  validation {
    condition     = contains(["dev", "sta", "pro", "tes"], var.env)
    error_message = "Environment must be one of: dev, sta, pro, tes."
  }
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster."

  validation {
    condition = (
      length(var.cluster_name) >= 1 &&
      length(var.cluster_name) <= 100 &&
      can(regex("^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.cluster_name))
    )
    error_message = "Cluster name must be 1-100 characters, start with a letter, end with alphanumeric, and contain only letters, numbers, and hyphens."
  }
}

variable "efs_csi_kms" {
  type        = string
  description = "KMS key ARN for EFS encryption. If not provided, AWS managed key will be used."
  default     = null

  validation {
    condition     = var.efs_csi_kms == null || can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]+:key/[a-f0-9-]+$", var.efs_csi_kms))
    error_message = "KMS key ARN must be a valid AWS KMS key ARN format or null."
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the EFS file system will be created."

  validation {
    condition     = can(regex("^vpc-[a-f0-9]{8}([a-f0-9]{9})?$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC ID format (vpc-xxxxxxxx or vpc-xxxxxxxxxxxxxxxxx)."
  }
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for EFS mount targets. Minimum 2 subnets recommended for high availability."

  validation {
    condition = (
      length(var.subnet_ids) >= 1 &&
      alltrue([
        for subnet_id in var.subnet_ids :
        can(regex("^subnet-[a-f0-9]{8}([a-f0-9]{9})?$", subnet_id))
      ])
    )
    error_message = "Subnet IDs must be valid AWS subnet ID format and at least one subnet must be provided. Format: subnet-xxxxxxxx or subnet-xxxxxxxxxxxxxxxxx."
  }
}

variable "performance_mode" {
  type        = string
  description = "Performance mode for EFS (generalPurpose or maxIO)."
  default     = "generalPurpose"

  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.performance_mode)
    error_message = "Performance mode must be either 'generalPurpose' or 'maxIO'."
  }
}

variable "throughput_mode" {
  type        = string
  description = "Throughput mode for EFS (bursting or provisioned)."
  default     = "bursting"

  validation {
    condition     = contains(["bursting", "provisioned"], var.throughput_mode)
    error_message = "Throughput mode must be either 'bursting' or 'provisioned'."
  }
}

variable "provisioned_throughput_in_mibps" {
  type        = number
  description = "Provisioned throughput in MiB/s. Only applicable when throughput_mode is 'provisioned'."
  default     = null

  validation {
    condition = var.provisioned_throughput_in_mibps == null || (
      var.provisioned_throughput_in_mibps >= 1 &&
      var.provisioned_throughput_in_mibps <= 1024
    )
    error_message = "Provisioned throughput must be between 1 and 1024 MiB/s or null."
  }
}

variable "create_default_storage_class" {
  type        = bool
  description = "Whether to create a default EFS storage class."
  default     = true
}

variable "storage_class_name" {
  type        = string
  description = "Name for the EFS storage class."
  default     = "efs-default"

  validation {
    condition = (
      length(var.storage_class_name) >= 1 &&
      length(var.storage_class_name) <= 253 &&
      can(regex("^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$", var.storage_class_name))
    )
    error_message = "Storage class name must be 1-253 characters, start/end with alphanumeric, and contain only lowercase letters, numbers, periods, and hyphens."
  }
}

variable "access_points" {
  type = list(object({
    name = string
    path = string
    creation_info = object({
      owner_gid   = number
      owner_uid   = number
      permissions = string
    })
    posix_user = object({
      gid = number
      uid = number
    })
  }))
  description = "List of EFS access points to create."
  default     = []

  validation {
    condition = alltrue([
      for ap in var.access_points :
      can(regex("^/.*$", ap.path)) &&
      can(regex("^[0-7]{3,4}$", ap.creation_info.permissions)) &&
      ap.creation_info.owner_gid >= 0 && ap.creation_info.owner_gid <= 4294967294 &&
      ap.creation_info.owner_uid >= 0 && ap.creation_info.owner_uid <= 4294967294 &&
      ap.posix_user.gid >= 0 && ap.posix_user.gid <= 4294967294 &&
      ap.posix_user.uid >= 0 && ap.posix_user.uid <= 4294967294
    ])
    error_message = "Access points must have valid paths (starting with /), octal permissions (3-4 digits), and valid UID/GID values (0-4294967294)."
  }
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to EFS resources."
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.tags :
      length(k) <= 128 && length(v) <= 256
    ])
    error_message = "Tag keys must be ≤128 characters and values ≤256 characters."
  }
}