variable "create_test_user" {
  description = "Whether to create a test SFTP user"
  type        = bool
  default     = false
}

variable "users" {
  description = "List of SFTP users. Use public_key as a string - for multiple keys, separate with commas."
  type = list(object({
    username   = string
    home_dir   = string
    public_key = string
    role_arn   = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for user in var.users :
      try(length(split(",", user.public_key)), 0) <= 50
    ])
    error_message = "Maximum of 50 public keys allowed per user as per AWS Transfer Family limits."
  }

  validation {
    condition = alltrue([
      for user in var.users :
      user.public_key != "" && try(length(split(",", user.public_key)) == length(distinct(split(",", user.public_key))), true)
    ])
    error_message = "Public key is required and duplicate public keys are not allowed for the same user."
  }

  validation {
    condition = alltrue(flatten([
      for user in var.users : [
        for key in [for k in split(",", user.public_key) : trimspace(k)] :
        can(regex("^(ssh-rsa|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|ssh-ed25519) AAAA[A-Za-z0-9+/]+[=]{0,3}( .+)?$", key))
      ]
    ]))
    error_message = "All public keys must be in the format '<key-type> <base64-encoded-key> [comment]' where key-type is one of: ssh-rsa (including rsa-sha2-256 and rsa-sha2-512), ecdsa-sha2-nistp256, ecdsa-sha2-nistp384, ecdsa-sha2-nistp521, or ssh-ed25519. The comment is optional."
  }

  validation {
    condition = alltrue([
      for user in var.users :
      user.role_arn == null ||
      user.role_arn == "" ||
      can(regex("^arn:aws:iam::[0-9]{12}:role/.+$", user.role_arn))
    ])
    error_message = "If provided, role_arn must be a valid AWS IAM role ARN in the format: arn:aws:iam::123456789012:role/role-name"
  }
}

variable "server_id" {
  description = "ID of the Transfer Family server"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for SFTP storage"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for SFTP storage"
  type        = string
}

variable "kms_key_id" {
  description = "encryption key"
  type        = string
  default     = null
}