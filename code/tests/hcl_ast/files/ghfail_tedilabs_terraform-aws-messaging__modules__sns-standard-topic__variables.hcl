variable "name" {
  description = "(Required) The name of the SNS topic. Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long."
  type        = string
  nullable    = false

  validation {
    condition     = !endswith(var.name, ".fifo")
    error_message = "For a FIFO topic, the name must end with the `.fifo` suffix."
  }
}

variable "display_name" {
  description = "(Optional) The display name to use for a topic with SMS subscriptions."
  type        = string
  default     = ""
  nullable    = false
}

variable "policy" {
  description = "(Optional) A valid policy JSON document. The resource-based policy defines who can publish or subscribe to the SNS topic."
  type        = string
  default     = null
}

variable "data_protection_policy" {
  description = "(Optional) A valid policy JSON document. The data protection policy defines your own rules and policies to audit and control the content for data in motion, as opposed to data at rest."
  type        = string
  default     = null
}

variable "delivery_policy" {
  description = "(Optional) The SNS delivery policy."
  type        = string
  default     = null
}

variable "subscriptions_by_email" {
  description = <<EOF
  (Optional) A configuration for email subscriptions to the SNS topic. Deliver messages to the subscriber via SMTP. Until the subscription is confirmed, AWS does not allow Terraform to delete / unsubscribe the subscription. If you destroy an unconfirmed subscription, Terraform will remove the subscription from its state but the subscription will still exist in AWS. Each block of `subscriptions_by_email` as defined below.
    (Required) `email` - An email address that can receive notifications from the SNS topic.
    (Optional) `filter_policy` - The configuration to filter the messages that a subscriber receives. Additions or changes to the filter policy require up to 15 minutes to fully take effect. `filter_policy` as defined below.
      (Optional) `enabled` - Whether to enable the filter policy. Defaults to `false`.
      (Optional) `scope` - Determine how the filter policy will be applied to the message.
  Valid values are `ATTRIBUTES` and `BODY`. Defaults to `ATTRIBUTES`.
        `ATTRIBUTES` - The filter policy will be applied to the message attributes.
        `BODY` - The filter policy will be applied to the message body.
    (Optional) `redrive_policy` - The configuration to send undeliverable messages to a dead-letter queue. `redrive_policy` as defined below.
      (Optional) `dead_letter_sqs_queue` - The ARN of the SQS queue to which Amazon SNS can send undeliverable messages.
  EOF
  type = list(object({
    email = string
    filter_policy = optional(object({
      enabled = optional(bool, false)
      scope   = optional(string, "ATTRIBUTES")
      policy  = optional(string)
    }), {})
    redrive_policy = optional(object({
      dead_letter_sqs_queue = optional(string)
    }), {})
  }))
  default  = []
  nullable = false

  validation {
    condition = alltrue([
      for subscription in var.subscriptions_by_email :
      contains(["ATTRIBUTES", "BODY"], subscription.filter_policy.scope)
      if subscription.filter_policy.enabled
    ])
    error_message = "Valid values for `filter_policy.scope` are `ATTRIBUTES` and `BODY`."
  }
  validation {
    condition = alltrue([
      for subscription in var.subscriptions_by_email :
      subscription.filter_policy.policy == null ||
      can(jsondecode(subscription.filter_policy.policy))
      if subscription.filter_policy.enabled
    ])
    error_message = "`filter_policy.policy` must be JSON string."
  }
}

variable "subscriptions_by_email_json" {
  description = <<EOF
  (Optional) A configuration for JSON-encoded email subscriptions to the SNS topic. Deliver JSON-encoded messages to the subscriber via SMTP. Until the subscription is confirmed, AWS does not allow Terraform to delete / unsubscribe the subscription. If you destroy an unconfirmed subscription, Terraform will remove the subscription from its state but the subscription will still exist in AWS. Each block of `subscriptions_by_email_json` as defined below.
    (Required) `email` - An email address that can receive notifications from the SNS topic.
    (Optional) `filter_policy` - The configuration to filter the messages that a subscriber receives. Additions or changes to the filter policy require up to 15 minutes to fully take effect. `filter_policy` as defined below.
      (Optional) `enabled` - Whether to enable the filter policy. Defaults to `false`.
      (Optional) `scope` - Determine how the filter policy will be applied to the message.
  Valid values are `ATTRIBUTES` and `BODY`. Defaults to `ATTRIBUTES`.
        `ATTRIBUTES` - The filter policy will be applied to the message attributes.
        `BODY` - The filter policy will be applied to the message body.
    (Optional) `redrive_policy` - The configuration to send undeliverable messages to a dead-letter queue. `redrive_policy` as defined below.
      (Optional) `dead_letter_sqs_queue` - The ARN of the SQS queue to which Amazon SNS can send undeliverable messages.
  EOF
  type = list(object({
    email = string
    filter_policy = optional(object({
      enabled = optional(bool, false)
      scope   = optional(string, "ATTRIBUTES")
      policy  = optional(string)
    }), {})
    redrive_policy = optional(object({
      dead_letter_sqs_queue = optional(string)
    }), {})
  }))
  default  = []
  nullable = false

  validation {
    condition = alltrue([
      for subscription in var.subscriptions_by_email_json :
      contains(["ATTRIBUTES", "BODY"], subscription.filter_policy.scope)
      if subscription.filter_policy.enabled
    ])
    error_message = "Valid values for `filter_policy.scope` are `ATTRIBUTES` and `BODY`."
  }
  validation {
    condition = alltrue([
      for subscription in var.subscriptions_by_email_json :
      subscription.filter_policy.policy == null ||
      can(jsondecode(subscription.filter_policy.policy))
      if subscription.filter_policy.enabled
    ])
    error_message = "`filter_policy.policy` must be JSON string."
  }
}

variable "subscriptions_by_lambda" {
  description = <<EOF
  (Optional) A configuration for Lambda Function subscriptions to the SNS topic. Deliver JSON-encoded messages to the Lambda function. Each block of `subscriptions_by_lambda` as defined below.
    (Required) `name` - The name of the subscription to the SNS topic. This value is only used internally within Terraform code.
    (Required) `function` - The ARN of the AWS Lambda function that can receive notifications from the SNS topic.
    (Optional) `filter_policy` - The configuration to filter the messages that a subscriber receives. Additions or changes to the filter policy require up to 15 minutes to fully take effect. `filter_policy` as defined below.
      (Optional) `enabled` - Whether to enable the filter policy. Defaults to `false`.
      (Optional) `scope` - Determine how the filter policy will be applied to the message.
  Valid values are `ATTRIBUTES` and `BODY`. Defaults to `ATTRIBUTES`.
        `ATTRIBUTES` - The filter policy will be applied to the message attributes.
        `BODY` - The filter policy will be applied to the message body.
    (Optional) `redrive_policy` - The configuration to send undeliverable messages to a dead-letter queue. `redrive_policy` as defined below.
      (Optional) `dead_letter_sqs_queue` - The ARN of the SQS queue to which Amazon SNS can send undeliverable messages.
  EOF
  type = list(object({
    name     = string
    function = string
    filter_policy = optional(object({
      enabled = optional(bool, false)
      scope   = optional(string, "ATTRIBUTES")
      policy  = optional(string)
    }), {})
    redrive_policy = optional(object({
      dead_letter_sqs_queue = optional(string)
    }), {})
  }))
  default  = []
  nullable = false

  validation {
    condition = alltrue([
      for subscription in var.subscriptions_by_lambda :
      contains(["ATTRIBUTES", "BODY"], subscription.filter_policy.scope)
      if subscription.filter_policy.enabled
    ])
    error_message = "Valid values for `filter_policy.scope` are `ATTRIBUTES` and `BODY`."
  }
  validation {
    condition = alltrue([
      for subscription in var.subscriptions_by_lambda :
      subscription.filter_policy.policy == null ||
      can(jsondecode(subscription.filter_policy.policy))
      if subscription.filter_policy.enabled
    ])
    error_message = "`filter_policy.policy` must be JSON string."
  }
}

variable "subscriptions_by_sqs" {
  description = <<EOF
  (Optional) A configuration for SQS Queue subscriptions to the SNS topic. Deliver JSON-encoded messages to the SQS queue. Each block of `subscriptions_by_sqs` as defined below.
    (Required) `name` - The name of the subscription to the SNS topic. This value is only used internally within Terraform code.
    (Required) `queue` - The ARN of the AWS SQS queue that can receive notifications from the SNS topic.
    (Optional) `raw_message_delivery_enabled` - Whether to enable raw message delivery. Raw messages are free of JSON formatting. Defaults to `false`.
    (Optional) `filter_policy` - The configuration to filter the messages that a subscriber receives. Additions or changes to the filter policy require up to 15 minutes to fully take effect. `filter_policy` as defined below.
      (Optional) `enabled` - Whether to enable the filter policy. Defaults to `false`.
      (Optional) `scope` - Determine how the filter policy will be applied to the message.
  Valid values are `ATTRIBUTES` and `BODY`. Defaults to `ATTRIBUTES`.
        `ATTRIBUTES` - The filter policy will be applied to the message attributes.
        `BODY` - The filter policy will be applied to the message body.
    (Optional) `redrive_policy` - The configuration to send undeliverable messages to a dead-letter queue. `redrive_policy` as defined below.
      (Optional) `dead_letter_sqs_queue` - The ARN of the SQS queue to which Amazon SNS can send undeliverable messages.
  EOF
  type = list(object({
    name                         = string
    queue                        = string
    raw_message_delivery_enabled = optional(bool, false)
    filter_policy = optional(object({
      enabled = optional(bool, false)
      scope   = optional(string, "ATTRIBUTES")
      policy  = optional(string)
    }), {})
    redrive_policy = optional(object({
      dead_letter_sqs_queue = optional(string)
    }), {})
  }))
  default  = []
  nullable = false

  validation {
    condition = alltrue([
      for subscription in var.subscriptions_by_sqs :
      contains(["ATTRIBUTES", "BODY"], subscription.filter_policy.scope)
      if subscription.filter_policy.enabled
    ])
    error_message = "Valid values for `filter_policy.scope` are `ATTRIBUTES` and `BODY`."
  }
  validation {
    condition = alltrue([
      for subscription in var.subscriptions_by_sqs :
      subscription.filter_policy.policy == null ||
      can(jsondecode(subscription.filter_policy.policy))
      if subscription.filter_policy.enabled
    ])
    error_message = "`filter_policy.policy` must be JSON string."
  }
}


variable "xray_tracing_enabled" {
  description = "(Optional) Whether to activate AWS X-Ray Active Tracing mode for the SNS topic. If set to Active, Amazon SNS will vend X-Ray segment data to topic owner account if the sampled flag in the tracing header is true. Defaults to `false`, and the topic passes through the tracing header it receives from an Amazon SNS publisher to its subscriptions."
  type        = bool
  default     = false
  nullable    = false
}

variable "signature_version" {
  description = "(Optional) The signature version corresponds to the hashing algorithm used while creating the signature of the notifications, subscription confirmations, or unsubscribe confirmation messages sent by Amazon SNS. Defaults to `1`."
  type        = number
  default     = 1
  nullable    = false
}

variable "encryption_at_rest" {
  description = <<EOF
  (Optional) A configuration to encrypt at rest in the SNS topic. Amazon SNS provides in-transit encryption by default. Enabling server-side encryption adds at-rest encryption to your topic. Amazon SNS encrypts your message as soon as it is received. The message is decrypted immediately prior to delivery. `encryption_at_rest` as defined below.
    (Optional) `enabled` - Whether to enable encryption at rest. Defaults to `false`.
    (Optional) `kms_key` - The ID of AWS KMS CMK (Customer Master Key) used for the encryption.
  EOF
  type = object({
    enabled = optional(bool, false)
    kms_key = optional(string)
  })
  default  = {}
  nullable = false
}

variable "tags" {
  description = "(Optional) A map of tags to add to all resources."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "module_tags_enabled" {
  description = "(Optional) Whether to create AWS Resource Tags for the module informations."
  type        = bool
  default     = true
  nullable    = false
}


###################################################
# Resource Group
###################################################




variable "resource_group" {
  description = <<EOF
  (Optional) A configurations of Resource Group for this module. `resource_group` as defined below.
    (Optional) `enabled` - Whether to create Resource Group to find and group AWS resources which are created by this module. Defaults to `true`.
    (Optional) `name` - The name of Resource Group. A Resource Group name can have a maximum of 127 characters, including letters, numbers, hyphens, dots, and underscores. The name cannot start with `AWS` or `aws`. If not provided, a name will be generated using the module name and instance name.
    (Optional) `description` - The description of Resource Group. Defaults to `Managed by Terraform.`.
  EOF
  type = object({
    enabled     = optional(bool, true)
    name        = optional(string, "")
    description = optional(string, "Managed by Terraform.")
  })
  default  = {}
  nullable = false
}
