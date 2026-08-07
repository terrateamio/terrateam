# Groups
variable "sso_groups" {
  description = "Names of the groups you wish to create in IAM Identity Center."
  type = map(object({
    group_name        = string
    group_description = optional(string, null)
  }))
  default = {}
}
variable "existing_sso_groups" {
  description = "Names of the existing groups that you wish to reference from IAM Identity Center."
  type = map(object({
    group_name = string
  }))
  default = {}
}

# Users
variable "sso_users" {
  description = "Names of the users you wish to create in IAM Identity Center."
  type = map(object({
    display_name     = optional(string)
    user_name        = string
    group_membership = list(string)
    # Name
    given_name       = string
    middle_name      = optional(string, null)
    family_name      = string
    name_formatted   = optional(string)
    honorific_prefix = optional(string, null)
    honorific_suffix = optional(string, null)
    # Email
    email            = string
    email_type       = optional(string, null)
    is_primary_email = optional(bool, true)
    # Phone Number
    phone_number            = optional(string, null)
    phone_number_type       = optional(string, null)
    is_primary_phone_number = optional(bool, true)
    # Address
    country            = optional(string, " ")
    locality           = optional(string, " ")
    address_formatted  = optional(string)
    postal_code        = optional(string, " ")
    is_primary_address = optional(bool, true)
    region             = optional(string, " ")
    street_address     = optional(string, " ")
    address_type       = optional(string, null)
    # Additional
    user_type          = optional(string, null)
    title              = optional(string, null)
    locale             = optional(string, null)
    nickname           = optional(string, null)
    preferred_language = optional(string, null)
    profile_url        = optional(string, null)
    timezone           = optional(string, null)
  }))
  default = {}

  validation {
    condition     = alltrue([for user in values(var.sso_users) : length(user.user_name) > 1 && length(user.user_name) <= 128])
    error_message = "The name of one of the defined IAM Identity Store (SSO) Users is too long. User_names can be a maxmium of 128 characters. Please ensure all user_names are 100 characters or less, and try again."
  }
}
variable "existing_sso_users" {
  description = "Names of the existing users that you wish to reference from IAM Identity Center."
  type = map(object({
    user_name        = string
    group_membership = optional(list(string), null) // only used if your IdP only syncs users, and you wish to manage which groups they should go in
  }))
  default = {}
}
variable "existing_google_sso_users" {
  description = "Names of the existing Google users that you wish to reference from IAM Identity Center."
  type = map(object({
    user_name        = string
    group_membership = optional(list(string), null) // only used if your IdP only syncs users, and you wish to manage which groups they should go in
  }))
  default = {}
}


# Permission Sets
variable "permission_sets" {
  description = "Permission Sets that you wish to create in IAM Identity Center. This variable is a map of maps containing Permission Set names as keys. See permission_sets description in README for information about map values."
  type        = any
  default     = {}
}
variable "existing_permission_sets" {
  description = "Names of the existing permission_sets that you wish to reference from IAM Identity Center."
  type = map(object({
    permission_set_name = string
  }))
  default = {}
}

#  Account Assignments
variable "account_assignments" {
  description = "List of maps containing mapping between user/group, permission set and assigned accounts list. See account_assignments description in README for more information about map values."
  type = map(object({
    principal_name  = string
    principal_type  = string
    principal_idp   = string # acceptable values are either "INTERNAL" or "EXTERNAL"
    permission_sets = list(string)
    account_ids     = list(string)
  }))

  default = {}
}

# Applications 
variable "sso_applications" {
  description = "List of applications to be created in IAM Identity Center"
  type = map(object({
    name                     = string
    application_provider_arn = string
    description              = optional(string)
    portal_options = optional(object({
      sign_in_options = optional(object({
        application_url = optional(string)
        origin          = string
      }))
      visibility = optional(string)
    }))
    status              = string # acceptable values are "ENABLED" or "DISABLED"
    client_token        = optional(string)
    tags                = optional(map(string))
    assignment_required = bool # Resource: aws_ssoadmin_application_assignment_configuration
    assignments_access_scope = optional(
      list(object({
        authorized_targets = optional(list(string)) # List of application names
        scope              = string
      }))
    )                                          # Resource: aws_ssoadmin_application_access_scope
    group_assignments = optional(list(string)) # Resource aws_ssoadmin_application_assignment, keeping it separated for groups
    user_assignments  = optional(list(string)) # Resource aws_ssoadmin_application_assignment, keeping it separated for users
  }))
  default = {}
  validation {
    condition = alltrue([
      for app in values(var.sso_applications) :
      app.application_provider_arn != null &&
      app.application_provider_arn != ""
    ])
    error_message = "The application_provider_arn field is mandatory for all applications."
  }
}

#Access Control Attributes
variable "sso_instance_access_control_attributes" {
  description = "List of attributes for access control. This is used to create the enable and use attributes for access control."
  type = list(object({
    attribute_name = string
    source = set(string)
  }))
  default = []
  validation {
    condition = alltrue([
      for attr in var.sso_instance_access_control_attributes :
      attr.attribute_name != null &&
      attr.attribute_name != ""
    ])
    error_message = "The attribute_name field is mandatory for all attributes."
  }
  validation {
    condition = alltrue([
      for attr in var.sso_instance_access_control_attributes :
      attr.source != null &&
      length(attr.source) > 0 &&  # checks if the set is not empty
      alltrue([for s in attr.source : s != ""]) # checks no empty strings in set
    ])
    error_message = "The attribute source is mandatory and must contain non-empty strings."
  }
}
