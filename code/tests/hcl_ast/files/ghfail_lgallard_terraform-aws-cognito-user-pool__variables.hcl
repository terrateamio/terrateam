#
# aws_cognito_user_pool
#
variable "enabled" {
  description = "Change to false to avoid deploying any resources"
  type        = bool
  default     = true
}

variable "user_pool_name" {
  description = "The name of the user pool"
  type        = string
}

variable "user_pool_tier" {
  type        = string
  description = "Cognito User Pool tier. Valid values: LITE, ESSENTIALS, PLUS."
  default     = "ESSENTIALS"
  validation {
    condition     = contains(["LITE", "ESSENTIALS", "PLUS"], var.user_pool_tier)
    error_message = "user_pool_tier must be one of: LITE, ESSENTIALS, PLUS"
  }
}

variable "email_verification_message" {
  description = "A string representing the email verification message"
  type        = string
  default     = null
}

variable "email_verification_subject" {
  description = "A string representing the email verification subject"
  type        = string
  default     = null
}

# username_configuration
variable "username_configuration" {
  description = "The Username Configuration. Setting `case_sensitive` specifies whether username case sensitivity will be applied for all users in the user pool through Cognito APIs"
  type        = map(any)
  default     = {}
}

# admin_create_user_config
variable "admin_create_user_config" {
  description = "The configuration for AdminCreateUser requests"
  type        = map(any)
  default     = {}
}

variable "admin_create_user_config_allow_admin_create_user_only" {
  description = "Set to True if only the administrator is allowed to create user profiles. Set to False if users can sign themselves up via an app"
  type        = bool
  default     = true
}

variable "temporary_password_validity_days" {
  description = "The user account expiration limit, in days, after which the account is no longer usable"
  type        = number
  default     = 7
}

variable "admin_create_user_config_email_message" {
  description = "The message template for email messages. Must contain `{username}` and `{####}` placeholders, for username and temporary password, respectively"
  type        = string
  default     = "{username}, your verification code is `{####}`"

  validation {
    condition     = can(regex("\\{username\\}", var.admin_create_user_config_email_message)) && can(regex("\\{####\\}", var.admin_create_user_config_email_message))
    error_message = "Email message template must contain {username} and {####} placeholders and cannot contain potentially malicious content."
  }

  validation {
    condition     = !can(regex("(?i)(script|javascript|vbscript|onload|onerror|onclick)", var.admin_create_user_config_email_message))
    error_message = "Email message template cannot contain potentially malicious script content for security."
  }
}


variable "admin_create_user_config_email_subject" {
  description = "The subject line for email messages"
  type        = string
  default     = "Your verification code"
}

variable "admin_create_user_config_sms_message" {
  description = "- The message template for SMS messages. Must contain `{username}` and `{####}` placeholders, for username and temporary password, respectively"
  type        = string
  default     = "Your username is {username} and temporary password is `{####}`"

  validation {
    condition     = can(regex("\\{username\\}", var.admin_create_user_config_sms_message)) && can(regex("\\{####\\}", var.admin_create_user_config_sms_message))
    error_message = "SMS message template must contain {username} and {####} placeholders and cannot contain potentially malicious content."
  }

  validation {
    condition     = length(var.admin_create_user_config_sms_message) <= 140
    error_message = "SMS message template must not exceed 140 characters for SMS delivery compatibility."
  }
}

variable "alias_attributes" {
  description = "Attributes supported as an alias for this user pool. Possible values: phone_number, email, or preferred_username. Conflicts with `username_attributes`"
  type        = list(string)
  default     = null
}

variable "username_attributes" {
  description = "Specifies whether email addresses or phone numbers can be specified as usernames when a user signs up. Conflicts with `alias_attributes`"
  type        = list(string)
  default     = null
}

variable "deletion_protection" {
  description = "When active, DeletionProtection prevents accidental deletion of your user pool. Before you can delete a user pool that you have protected against deletion, you must deactivate this feature. Valid values are `ACTIVE` and `INACTIVE`."
  type        = string
  default     = "ACTIVE"
}

variable "auto_verified_attributes" {
  description = "The attributes to be auto-verified. Possible values: email, phone_number"
  type        = list(string)
  default     = []
}

# sms_configuration
variable "sms_configuration" {
  description = "The SMS Configuration"
  type        = map(any)
  default     = {}
}

variable "sms_configuration_external_id" {
  description = "The external ID used in IAM role trust relationships"
  type        = string
  default     = ""
}

variable "sms_configuration_sns_caller_arn" {
  description = "The ARN of the Amazon SNS caller. This is usually the IAM role that you've given Cognito permission to assume"
  type        = string
  default     = ""

  validation {
    condition = var.sms_configuration_sns_caller_arn == "" ? true : can(regex(
      "^arn:aws:iam::[0-9]{12}:role/[a-zA-Z0-9+=,.@_-]+$",
      var.sms_configuration_sns_caller_arn
    ))
    error_message = "SNS caller ARN must be a valid IAM role ARN format: arn:aws:iam::account:role/role-name."
  }
}

# device_configuration
variable "device_configuration" {
  description = "The configuration for the user pool's device tracking"
  type        = map(any)
  default     = {}
}

variable "device_configuration_challenge_required_on_new_device" {
  description = "Indicates whether a challenge is required on a new device. Only applicable to a new device"
  type        = bool
  default     = null
}

variable "device_configuration_device_only_remembered_on_user_prompt" {
  description = "If true, a device is only remembered on user prompt"
  type        = bool
  default     = null
}

# email_configuration
variable "email_configuration" {
  description = "The Email Configuration"
  type        = map(any)
  default     = {}
}

variable "email_configuration_configuration_set" {
  description = "The name of the configuration set"
  type        = string
  default     = null
}

variable "email_configuration_reply_to_email_address" {
  description = "The REPLY-TO email address"
  type        = string
  default     = ""
}

variable "email_configuration_source_arn" {
  description = "The ARN of the email source"
  type        = string
  default     = ""

  validation {
    condition = var.email_configuration_source_arn == "" ? true : can(regex(
      "^arn:aws:ses:[a-z0-9-]+:[0-9]{12}:identity/.+$",
      var.email_configuration_source_arn
    ))
    error_message = "Email source ARN must be a valid SES identity ARN format: arn:aws:ses:region:account:identity/domain-or-email."
  }
}

variable "email_configuration_email_sending_account" {
  description = "Instruct Cognito to either use its built-in functional or Amazon SES to send out emails. Allowed values: `COGNITO_DEFAULT` or `DEVELOPER`"
  type        = string
  default     = "COGNITO_DEFAULT"
}

variable "email_configuration_from_email_address" {
  description = "Sender's email address or sender's display name with their email address (e.g. `john@example.com`, `John Smith <john@example.com>` or `\"John Smith Ph.D.\" <john@example.com>)`. Escaped double quotes are required around display names that contain certain characters as specified in RFC 5322"
  type        = string
  default     = null
}

variable "email_mfa_configuration" {
  description = "Configuration block for configuring email Multi-Factor Authentication (MFA)"
  type = object({
    message = string
    subject = string
  })
  default = null
}

# lambda_config
variable "lambda_config" {
  description = "A container for the AWS Lambda triggers associated with the user pool"
  type        = any
  default     = {}
}

variable "lambda_config_create_auth_challenge" {
  description = "The ARN of the lambda creating an authentication challenge."
  type        = string
  default     = null

  validation {
    condition = var.lambda_config_create_auth_challenge == null ? true : can(regex(
      "^arn:aws:lambda:[a-z0-9-]+:[0-9]{12}:function:[a-zA-Z0-9-_]+(?::[a-zA-Z0-9-_]+)?$",
      var.lambda_config_create_auth_challenge
    ))
    error_message = "Lambda ARN must be a valid AWS Lambda function ARN format: arn:aws:lambda:region:account:function:name[:alias]."
  }
}

variable "lambda_config_custom_message" {
  description = "A custom Message AWS Lambda trigger."
  type        = string
  default     = null

  validation {
    condition = var.lambda_config_custom_message == null ? true : can(regex(
      "^arn:aws:lambda:[a-z0-9-]+:[0-9]{12}:function:[a-zA-Z0-9-_]+(?::[a-zA-Z0-9-_]+)?$",
      var.lambda_config_custom_message
    ))
    error_message = "Lambda ARN must be a valid AWS Lambda function ARN format: arn:aws:lambda:region:account:function:name[:alias]."
  }
}

variable "lambda_config_define_auth_challenge" {
  description = "Defines the authentication challenge."
  type        = string
  default     = null

  validation {
    condition = var.lambda_config_define_auth_challenge == null ? true : can(regex(
      "^arn:aws:lambda:[a-z0-9-]+:[0-9]{12}:function:[a-zA-Z0-9-_]+(?::[a-zA-Z0-9-_]+)?$",
      var.lambda_config_define_auth_challenge
    ))
    error_message = "Lambda ARN must be a valid AWS Lambda function ARN format: arn:aws:lambda:region:account:function:name[:alias]."
  }
}

variable "lambda_config_post_authentication" {
  description = "A post-authentication AWS Lambda trigger"
  type        = string
  default     = null

  validation {
    condition = var.lambda_config_post_authentication == null ? true : can(regex(
      "^arn:aws:lambda:[a-z0-9-]+:[0-9]{12}:function:[a-zA-Z0-9-_]+(?::[a-zA-Z0-9-_]+)?$",
      var.lambda_config_post_authentication
    ))
    error_message = "Lambda ARN must be a valid AWS Lambda function ARN format: arn:aws:lambda:region:account:function:name[:alias]."
  }
}

variable "lambda_config_post_confirmation" {
  description = "A post-confirmation AWS Lambda trigger"
  type        = string
  default     = null

  validation {
    condition = var.lambda_config_post_confirmation == null ? true : can(regex(
      "^arn:aws:lambda:[a-z0-9-]+:[0-9]{12}:function:[a-zA-Z0-9-_]+(?::[a-zA-Z0-9-_]+)?$",
      var.lambda_config_post_confirmation
    ))
    error_message = "Lambda ARN must be a valid AWS Lambda function ARN format: arn:aws:lambda:region:account:function:name[:alias]."
  }
}

variable "lambda_config_pre_authentication" {
  description = "A pre-authentication AWS Lambda trigger"
  type        = string
  default     = null

  validation {
    condition = var.lambda_config_pre_authentication == null ? true : can(regex(
      "^arn:aws:lambda:[a-z0-9-]+:[0-9]{12}:function:[a-zA-Z0-9-_]+(?::[a-zA-Z0-9-_]+)?$",
      var.lambda_config_pre_authentication
    ))
    error_message = "Lambda ARN must be a valid AWS Lambda function ARN format: arn:aws:lambda:region:account:function:name[:alias]."
  }
}
variable "lambda_config_pre_sign_up" {
  description = "A pre-registration AWS Lambda trigger"
  type        = string
  default     = null

  validation {
    condition = var.lambda_config_pre_sign_up == null ? true : can(regex(
      "^arn:aws:lambda:[a-z0-9-]+:[0-9]{12}:function:[a-zA-Z0-9-_]+(?::[a-zA-Z0-9-_]+)?$",
      var.lambda_config_pre_sign_up
    ))
    error_message = "Lambda ARN must be a valid AWS Lambda function ARN format: arn:aws:lambda:region:account:function:name[:alias]."
  }
}

variable "lambda_config_pre_token_generation" {
  description = "(deprecated) Allow to customize identity token claims before token generation"
  type        = string
  default     = null

  validation {
    condition = var.lambda_config_pre_token_generation == null ? true : can(regex(
      "^arn:aws:lambda:[a-z0-9-]+:[0-9]{12}:function:[a-zA-Z0-9-_]+(?::[a-zA-Z0-9-_]+)?$",
      var.lambda_config_pre_token_generation
    ))
    error_message = "Lambda ARN must be a valid AWS Lambda function ARN format: arn:aws:lambda:region:account:function:name[:alias]."
  }
}

variable "lambda_config_pre_token_generation_config" {
  description = "Allow to customize identity token claims before token generation"
  type        = any
  default     = {}
}

variable "lambda_config_user_migration" {
  description = "The user migration Lambda config type"
  type        = string
  default     = null

  validation {
    condition = var.lambda_config_user_migration == null ? true : can(regex(
      "^arn:aws:lambda:[a-z0-9-]+:[0-9]{12}:function:[a-zA-Z0-9-_]+(?::[a-zA-Z0-9-_]+)?$",
      var.lambda_config_user_migration
    ))
    error_message = "Lambda ARN must be a valid AWS Lambda function ARN format: arn:aws:lambda:region:account:function:name[:alias]."
  }
}

variable "lambda_config_verify_auth_challenge_response" {
  description = "Verifies the authentication challenge response"
  type        = string
  default     = null

  validation {
    condition = var.lambda_config_verify_auth_challenge_response == null ? true : can(regex(
      "^arn:aws:lambda:[a-z0-9-]+:[0-9]{12}:function:[a-zA-Z0-9-_]+(?::[a-zA-Z0-9-_]+)?$",
      var.lambda_config_verify_auth_challenge_response
    ))
    error_message = "Lambda ARN must be a valid AWS Lambda function ARN format: arn:aws:lambda:region:account:function:name[:alias]."
  }
}

variable "lambda_config_kms_key_id" {
  description = "The Amazon Resource Name of Key Management Service Customer master keys. Amazon Cognito uses the key to encrypt codes and temporary passwords sent to CustomEmailSender and CustomSMSSender."
  type        = string
  default     = null

  validation {
    condition = var.lambda_config_kms_key_id == null ? true : can(regex(
      "^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]{36}$|^[a-f0-9-]{36}$|^alias/[a-zA-Z0-9/_-]+$",
      var.lambda_config_kms_key_id
    ))
    error_message = "KMS key must be a valid ARN (arn:aws:kms:region:account:key/key-id), key ID (UUID), or alias (alias/name)."
  }
}

variable "lambda_config_custom_email_sender" {
  description = "A custom email sender AWS Lambda trigger."
  type        = any
  default     = {}

}

variable "lambda_config_custom_sms_sender" {
  description = "A custom SMS sender AWS Lambda trigger."
  type        = any
  default     = {}

}

variable "mfa_configuration" {
  description = "Set to enable multi-factor authentication. Must be one of the following values (ON, OFF, OPTIONAL)"
  type        = string
  default     = "OPTIONAL"

  validation {
    condition     = contains(["ON", "OFF", "OPTIONAL"], upper(var.mfa_configuration))
    error_message = "MFA configuration must be ON, OFF, or OPTIONAL (case-sensitive)."
  }
}

# software_token_mfa_configuration
variable "software_token_mfa_configuration" {
  description = "Configuration block for software token MFA (multifactor-auth). mfa_configuration must also be enabled for this to work"
  type        = map(any)
  default     = {}
}

variable "software_token_mfa_configuration_enabled" {
  description = "If true, and if mfa_configuration is also enabled, multi-factor authentication by software TOTP generator will be enabled"
  type        = bool
  default     = false
}

# password_policy
variable "password_policy" {
  description = "A container for information about the user pool password policy"
  type = object({
    minimum_length                   = number,
    require_lowercase                = bool,
    require_numbers                  = bool,
    require_symbols                  = bool,
    require_uppercase                = bool,
    temporary_password_validity_days = number
    password_history_size            = number
  })
  default = null

  validation {
    condition = var.password_policy == null ? true : (
      var.password_policy.minimum_length >= 8 &&
      var.password_policy.minimum_length <= 99
    )
    error_message = "Password minimum length must be between 8 and 99 characters for security."
  }

  validation {
    condition = var.password_policy == null ? true : (
      # Require at least 3 out of 4 character types for strong security
      (var.password_policy.require_lowercase ? 1 : 0) +
      (var.password_policy.require_numbers ? 1 : 0) +
      (var.password_policy.require_symbols ? 1 : 0) +
      (var.password_policy.require_uppercase ? 1 : 0) >= 3
    )
    error_message = "Password policy must require at least 3 out of 4 character types (lowercase, numbers, symbols, uppercase) for security."
  }

  validation {
    condition = var.password_policy == null ? true : (
      var.password_policy.temporary_password_validity_days >= 1 &&
      var.password_policy.temporary_password_validity_days <= 365
    )
    error_message = "Password policy temporary_password_validity_days must be between 1 and 365 days per AWS limits."
  }

  validation {
    condition = var.password_policy == null ? true : (
      var.password_policy.password_history_size >= 0 &&
      var.password_policy.password_history_size <= 24
    )
    error_message = "Password policy password_history_size must be between 0 and 24 per AWS limits."
  }
}

variable "password_policy_minimum_length" {
  description = "The minimum length of the password policy that you have set"
  type        = number
  default     = 8

  validation {
    condition     = var.password_policy_minimum_length >= 8 && var.password_policy_minimum_length <= 99
    error_message = "Password minimum length must be between 8 and 99 characters for security (legacy variable validation)."
  }
}

variable "password_policy_require_lowercase" {
  description = "Whether you have required users to use at least one lowercase letter in their password"
  type        = bool
  default     = true
}

variable "password_policy_require_numbers" {
  description = "Whether you have required users to use at least one number in their password"
  type        = bool
  default     = true
}

variable "password_policy_require_symbols" {
  description = "Whether you have required users to use at least one symbol in their password"
  type        = bool
  default     = true
}

variable "password_policy_require_uppercase" {
  description = "Whether you have required users to use at least one uppercase letter in their password"
  type        = bool
  default     = true
}

variable "password_policy_temporary_password_validity_days" {
  description = "The user account expiration limit, in days, after which the account is no longer usable"
  type        = number
  default     = 7

  validation {
    condition     = var.password_policy_temporary_password_validity_days >= 1 && var.password_policy_temporary_password_validity_days <= 365
    error_message = "Temporary password validity must be between 1 and 365 days per AWS limits (legacy variable validation)."
  }
}

variable "password_policy_password_history_size" {
  description = "The number of previous passwords that users are prevented from reusing"
  type        = number
  default     = 0

  validation {
    condition     = var.password_policy_password_history_size >= 0 && var.password_policy_password_history_size <= 24
    error_message = "Password history size must be between 0 and 24 per AWS limits (legacy variable validation)."
  }
}

# schema
variable "schemas" {
  description = "A container with the schema attributes of a user pool. Maximum of 50 attributes"
  type        = list(any)
  default     = []
}

variable "string_schemas" {
  description = "A container with the string schema attributes of a user pool. Maximum of 50 attributes"
  type        = list(any)
  default     = []
}

variable "number_schemas" {
  description = "A container with the number schema attributes of a user pool. Maximum of 50 attributes"
  type        = list(any)
  default     = []
}

# schema lifecycle management
variable "ignore_schema_changes" {
  description = "Whether to ignore changes to Cognito User Pool schemas after creation. Set to true to prevent perpetual diffs when using custom schemas. This prevents AWS API errors since schema attributes cannot be modified or removed once created in Cognito. Due to Terraform limitations with conditional lifecycle blocks, this uses a dual-resource approach. Default is false for backward compatibility - set to true to enable the fix."
  type        = bool
  default     = false
}

# sms messages
variable "sms_authentication_message" {
  description = "A string representing the SMS authentication message"
  type        = string
  default     = null
}

variable "sms_verification_message" {
  description = "A string representing the SMS verification message"
  type        = string
  default     = null
}

# tags
variable "tags" {
  description = "A mapping of tags to assign to the User Pool"
  type        = map(string)
  default     = {}
}

# user_attribute_update_settings
variable "user_attribute_update_settings" {
  description = "Configuration block for user attribute update settings. Must contain key `attributes_require_verification_before_update` with list with only valid values of `email` and `phone_number`"
  type        = map(list(string))
  default     = null
}

# user_pool_add_ons
variable "user_pool_add_ons" {
  description = "Configuration block for user pool add-ons to enable user pool advanced security mode features"
  type        = map(any)
  default     = {}
}

variable "user_pool_add_ons_advanced_security_mode" {
  description = "The mode for advanced security, must be one of `OFF`, `AUDIT` or `ENFORCED`"
  type        = string
  default     = null

  validation {
    condition     = var.user_pool_add_ons_advanced_security_mode == null ? true : contains(["OFF", "AUDIT", "ENFORCED"], var.user_pool_add_ons_advanced_security_mode)
    error_message = "Advanced security mode must be OFF, AUDIT, or ENFORCED."
  }
}

variable "user_pool_add_ons_advanced_security_additional_flows" {
  description = "Mode of threat protection operation in custom authentication. Valid values are AUDIT or ENFORCED. Default is AUDIT"
  type        = string
  default     = null

  validation {
    condition     = var.user_pool_add_ons_advanced_security_additional_flows == null ? true : contains(["AUDIT", "ENFORCED"], var.user_pool_add_ons_advanced_security_additional_flows)
    error_message = "Invalid custom_auth_mode. Valid values: AUDIT, ENFORCED"
  }
}

# verification_message_template
variable "verification_message_template" {
  description = "The verification message templates configuration"
  type        = map(any)
  default     = {}
}

variable "verification_message_template_default_email_option" {
  description = "The default email option. Must be either `CONFIRM_WITH_CODE` or `CONFIRM_WITH_LINK`. Defaults to `CONFIRM_WITH_CODE`"
  type        = string
  default     = null
}

variable "verification_message_template_email_message_by_link" {
  description = "The email message template for sending a confirmation link to the user, it must contain the `{##Click Here##}` placeholder"
  type        = string
  default     = null
}

variable "verification_message_template_email_subject_by_link" {
  description = "The subject line for the email message template for sending a confirmation link to the user"
  type        = string
  default     = null
}

variable "verification_message_template_sms_message" {
  description = "SMS message template. Must contain the {####} placeholder. Conflicts with sms_verification_message argument."
  type        = string
  default     = null
}

variable "verification_message_template_email_message" {
  description = "The email message template for sending a confirmation code to the user, it must contain the `{####}` placeholder"
  type        = string
  default     = null
}

variable "verification_message_template_email_subject" {
  description = "The subject line for the email message template for sending a confirmation code to the user"
  type        = string
  default     = null
}

#
# aws_cognito_user_pool_domain
#
variable "domain" {
  description = "Cognito User Pool domain"
  type        = string
  default     = null

  validation {
    condition = var.domain == null ? true : (
      can(regex("^[a-z0-9][.a-z0-9-]*[a-z0-9]$", var.domain)) &&
      length(var.domain) >= 3 &&
      length(var.domain) <= 63
    )
    error_message = "Domain must be 3-63 characters, start and end with alphanumeric characters, and contain only lowercase letters, numbers, dots, and hyphens."
  }
}

variable "domain_certificate_arn" {
  description = "The ARN of an ISSUED ACM certificate in us-east-1 for a custom domain"
  type        = string
  default     = null
}

variable "domain_managed_login_version" {
  description = "The version number of managed login for your domain. 1 for hosted UI (classic), 2 for the newer managed login"
  type        = number
  default     = 1
}

#
# default_ui_customization
#
variable "default_ui_customization_image_file" {
  description = "Image file path for default UI customization"
  type        = string
  default     = null
}

variable "default_ui_customization_css" {
  description = "CSS file content for default UI customization"
  type        = string
  default     = null
}

#
# aws_cognito_user_pool_client
#
variable "clients" {
  description = "A container with the clients definitions"
  type        = any
  default     = []
}

variable "client_allowed_oauth_flows" {
  description = "The name of the application client"
  type        = list(string)
  default     = []
}

variable "client_allowed_oauth_flows_user_pool_client" {
  description = "Whether the client is allowed to follow the OAuth protocol when interacting with Cognito user pools"
  type        = bool
  default     = true
}

variable "client_allowed_oauth_scopes" {
  description = "List of allowed OAuth scopes (phone, email, openid, profile, and aws.cognito.signin.user.admin)"
  type        = list(string)
  default     = []
}

variable "client_auth_session_validity" {
  description = "Amazon Cognito creates a session token for each API request in an authentication flow. AuthSessionValidity is the duration, in minutes, of that session token. Your user pool native user must respond to each authentication challenge before the session expires. Valid values between 3 and 15. Default value is 3."
  type        = number
  default     = 3
}

variable "client_callback_urls" {
  description = "List of allowed callback URLs for the identity providers"
  type        = list(string)
  default     = []

  validation {
    condition = length(var.client_callback_urls) == 0 || alltrue([
      for url in var.client_callback_urls :
      can(regex("^https://[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9](?::[0-9]+)?(?:/.*)?$", url)) ||
      can(regex("^http://localhost(?::[0-9]+)?(?:/.*)?$", url))
    ])
    error_message = "Callback URLs must be valid HTTPS URLs (or HTTP localhost for development). URLs must start with https:// or http://localhost and have valid domain format."
  }
}

variable "client_default_redirect_uri" {
  description = "The default redirect URI. Must be in the list of callback URLs"
  type        = string
  default     = ""
}

variable "client_enable_token_revocation" {
  description = "Whether the client token can be revoked"
  type        = bool
  default     = true
}

variable "client_explicit_auth_flows" {
  description = "List of authentication flows (ADMIN_NO_SRP_AUTH, CUSTOM_AUTH_FLOW_ONLY, ALLOW_USER_PASSWORD_AUTH, ALLOW_ADMIN_USER_PASSWORD_AUTH)"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for flow in var.client_explicit_auth_flows :
      contains(["ADMIN_NO_SRP_AUTH", "CUSTOM_AUTH_FLOW_ONLY", "USER_SRP_AUTH", "ALLOW_CUSTOM_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_ADMIN_USER_PASSWORD_AUTH", "ALLOW_USER_PASSWORD_AUTH"], flow)
    ])
    error_message = "Authentication flows must be valid values: ADMIN_NO_SRP_AUTH, CUSTOM_AUTH_FLOW_ONLY, USER_SRP_AUTH, ALLOW_CUSTOM_AUTH, ALLOW_USER_SRP_AUTH, ALLOW_REFRESH_TOKEN_AUTH, ALLOW_ADMIN_USER_PASSWORD_AUTH, ALLOW_USER_PASSWORD_AUTH. Avoid password-based flows for security."
  }
}

variable "client_generate_secret" {
  description = "Should an application secret be generated"
  type        = bool
  default     = true
}

variable "client_logout_urls" {
  description = "List of allowed logout URLs for the identity providers"
  type        = list(string)
  default     = []

  validation {
    condition = length(var.client_logout_urls) == 0 || alltrue([
      for url in var.client_logout_urls :
      can(regex("^https://[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9](?::[0-9]+)?(?:/.*)?$", url)) ||
      can(regex("^http://localhost(?::[0-9]+)?(?:/.*)?$", url))
    ])
    error_message = "Logout URLs must be valid HTTPS URLs (or HTTP localhost for development). URLs must start with https:// or http://localhost and have valid domain format."
  }
}

variable "client_name" {
  description = "The name of the application client"
  type        = string
  default     = null
}

variable "client_read_attributes" {
  description = "List of user pool attributes the application client can read from"
  type        = list(string)
  default     = []
}

variable "client_prevent_user_existence_errors" {
  description = "Choose which errors and responses are returned by Cognito APIs during authentication, account confirmation, and password recovery when the user does not exist in the user pool. When set to ENABLED and the user does not exist, authentication returns an error indicating either the username or password was incorrect, and account confirmation and password recovery return a response indicating a code was sent to a simulated destination. When set to LEGACY, those APIs will return a UserNotFoundException exception if the user does not exist in the user pool."
  type        = string
  default     = null
}

variable "client_supported_identity_providers" {
  description = "List of provider names for the identity providers that are supported on this client"
  type        = list(string)
  default     = []
}

variable "client_write_attributes" {
  description = "List of user pool attributes the application client can write to"
  type        = list(string)
  default     = []
}

variable "client_access_token_validity" {
  description = "Time limit, between 5 minutes and 1 day, after which the access token is no longer valid and cannot be used. This value will be overridden if you have entered a value in `token_validity_units`."
  type        = number
  default     = 60

  validation {
    condition     = var.client_access_token_validity >= 5 && var.client_access_token_validity <= 1440
    error_message = "Access token validity must be between 5 minutes and 1440 minutes (1 day) per AWS limits."
  }
}

variable "client_id_token_validity" {
  description = "Time limit, between 5 minutes and 1 day, after which the ID token is no longer valid and cannot be used. Must be between 5 minutes and 1 day. Cannot be greater than refresh token expiration. This value will be overridden if you have entered a value in `token_validity_units`."
  type        = number
  default     = 60

  validation {
    condition     = var.client_id_token_validity >= 5 && var.client_id_token_validity <= 1440
    error_message = "ID token validity must be between 5 minutes and 1440 minutes (1 day) per AWS limits."
  }
}

variable "client_refresh_token_validity" {
  description = "The time limit in days refresh tokens are valid for. Must be between 60 minutes and 3650 days. This value will be overridden if you have entered a value in `token_validity_units`"
  type        = number
  default     = 30

  validation {
    condition     = var.client_refresh_token_validity >= 1 && var.client_refresh_token_validity <= 3650
    error_message = "Refresh token validity must be between 1 and 3650 days per AWS limits."
  }
}

variable "client_token_validity_units" {
  description = "Configuration block for units in which the validity times are represented in. Valid values for the following arguments are: `seconds`, `minutes`, `hours` or `days`."
  type        = any
  default = {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

}

variable "client_refresh_token_rotation" {
  description = "Configuration block for refresh token rotation. When enabled, refresh token rotation is a security feature that provides a new set of tokens (ID, access, and refresh tokens) each time a client exchanges a refresh token to get new tokens."
  type = object({
    feature                    = optional(string)
    retry_grace_period_seconds = optional(number)
  })
  default = {}

  validation {
    condition     = try(var.client_refresh_token_rotation.feature, null) == null || try(contains(["ENABLED", "DISABLED"], var.client_refresh_token_rotation.feature), false)
    error_message = "The refresh token rotation feature must be either 'ENABLED' or 'DISABLED'."
  }

  validation {
    condition     = try(var.client_refresh_token_rotation.retry_grace_period_seconds, null) == null || try(var.client_refresh_token_rotation.retry_grace_period_seconds >= 0 && var.client_refresh_token_rotation.retry_grace_period_seconds <= 60, false)
    error_message = "The retry grace period must be between 0 and 60 seconds per AWS limits."
  }
}

#
# aws_cognito_user_group
#
variable "user_groups" {
  description = "A container with the user_groups definitions"
  type        = list(any)
  default     = []

  validation {
    condition = length(var.user_groups) == 0 || (
      alltrue([for group in var.user_groups : lookup(group, "name", null) != null && lookup(group, "name", null) != ""]) &&
      length(distinct([for group in var.user_groups : lookup(group, "name", "")])) == length(var.user_groups)
    )
    error_message = "All user groups must have non-empty 'name' attributes and names must be unique."
  }
}

variable "user_group_name" {
  description = "The name of the user group"
  type        = string
  default     = null
}

variable "user_group_description" {
  description = "The description of the user group"
  type        = string
  default     = null
}

variable "user_group_precedence" {
  description = "The precedence of the user group"
  type        = number
  default     = null
}

variable "user_group_role_arn" {
  description = "The ARN of the IAM role to be associated with the user group"
  type        = string
  default     = null
}

#
# aws_cognito_resource_server
#
variable "resource_servers" {
  description = "A container with the resource_servers definitions"
  type        = list(any)
  default     = []
}

variable "resource_server_name" {
  description = "A name for the resource server"
  type        = string
  default     = null
}

variable "resource_server_identifier" {
  description = "An identifier for the resource server"
  type        = string
  default     = null
}

variable "resource_server_scope_name" {
  description = "The scope name"
  type        = string
  default     = null
}

variable "resource_server_scope_description" {
  description = "The scope description"
  type        = string
  default     = null
}

#
# Account Recovery Setting
#
variable "recovery_mechanisms" {
  description = "The list of Account Recovery Options"
  type        = list(any)
  default     = []
}

#
# aws_cognito_identity_provider
#
variable "identity_providers" {
  description = "List of identity provider configurations"
  type = list(object({
    provider_name     = string
    provider_type     = string
    attribute_mapping = optional(map(string), {})
    idp_identifiers   = optional(list(string), [])
    provider_details  = optional(map(string), {})
  }))
  default   = []
  sensitive = true

  validation {
    condition = alltrue([
      for provider in var.identity_providers :
      can(provider.provider_name) && can(provider.provider_type)
    ])
    error_message = "Each identity provider must have provider_name and provider_type defined. These are required fields for AWS Cognito identity provider configuration."
  }
}

variable "enable_propagate_additional_user_context_data" {
  description = "Enables the propagation of additional user context data"
  type        = bool
  default     = false
}

#
# sign_in_policy
#
variable "sign_in_policy" {
  description = "Configuration block for sign-in policy. Allows configuring additional sign-in mechanisms like OTP"
  type = object({
    allowed_first_auth_factors = list(string)
  })
  default = null
}

variable "sign_in_policy_allowed_first_auth_factors" {
  description = "List of allowed first authentication factors. Valid values: PASSWORD, EMAIL_OTP, SMS_OTP"
  type        = list(string)
  default     = []
}

#
# Managed Login Branding
#
variable "managed_login_branding_enabled" {
  description = "Whether to enable managed login branding. Requires awscc provider to be configured in root module. See README for setup instructions."

  type    = bool
  default = false
}

variable "managed_login_branding" {
  description = "Configuration for managed login branding. Map of branding configurations where each key represents a branding instance"
  type = map(object({
    client_id = string
    assets = optional(list(object({
      bytes       = string
      category    = string
      color_mode  = string
      extension   = string
      resource_id = optional(string)
    })), [])
    settings                    = optional(string)
    return_merged_resources     = optional(bool, false)
    use_cognito_provided_values = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for config in values(var.managed_login_branding) : alltrue([
        for asset in lookup(config, "assets", []) : contains([
          "FORM_LOGO", "PAGE_BACKGROUND", "FAVICON_ICO",
          "PAGE_HEADER_LOGO", "PAGE_FOOTER_LOGO", "EMAIL_GRAPHIC",
          "SMS_GRAPHIC", "AUTH_APP_GRAPHIC", "PASSWORD_GRAPHIC", "PASSKEY_GRAPHIC"
        ], asset.category)
      ])
    ])
    error_message = "Invalid asset category. Must be one of: FORM_LOGO, PAGE_BACKGROUND, FAVICON_ICO, PAGE_HEADER_LOGO, PAGE_FOOTER_LOGO, EMAIL_GRAPHIC, SMS_GRAPHIC, AUTH_APP_GRAPHIC, PASSWORD_GRAPHIC, PASSKEY_GRAPHIC"
  }

  validation {
    condition = alltrue([
      for config in values(var.managed_login_branding) : alltrue([
        for asset in lookup(config, "assets", []) : contains([
          "LIGHT", "DARK", "DYNAMIC"
        ], asset.color_mode)
      ])
    ])
    error_message = "Invalid color_mode. Must be one of: LIGHT, DARK, DYNAMIC"
  }

  validation {
    condition = alltrue([
      for config in values(var.managed_login_branding) : alltrue([
        for asset in lookup(config, "assets", []) : contains([
          "PNG", "JPG", "JPEG", "SVG", "ICO", "WEBP"
        ], upper(asset.extension))
      ])
    ])
    error_message = "Invalid file extension. Must be one of: PNG, JPG, JPEG, SVG, ICO, WEBP"
  }

  validation {
    condition = alltrue([
      for config in values(var.managed_login_branding) : alltrue([
        for asset in lookup(config, "assets", []) : length(asset.bytes) <= 2796203 # 2MB base64 encoded (2MB * 4/3)
      ])
    ])
    error_message = "Asset file size must not exceed 2MB when base64 encoded"
  }
}
