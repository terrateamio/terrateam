
variable "name" {
  type        = string
  description = "Policy definition name."
}

variable "display_name" {
  type        = string
  description = "Display name for the policy."
}

variable "description" {
  type        = string
  default     = ""
  description = "Description of the policy."
}

variable "mode" {
  type        = string
  default     = "All"
  description = "Determines which resource types are evaluated for a policy definition"
  validation {
    condition = contains([
      # Resource Manager Modes
      "All", "Indexed",
      # Resource Provider Modes
      "Microsoft.ContainerService.Data",
      "Microsoft.CustomerLockbox.Data",
      "Microsoft.DataCatalog.Data",
      "Microsoft.KeyVault.Data",
      "Microsoft.Kubernetes.Data",
      "Microsoft.MachineLearningServices.Data",
      "Microsoft.Network.Data",
    "Microsoft.Synapse.Data"], var.mode)
    error_message = "Mode must be one of: (Resource Provider Modes) All, Indexed. (Resource Provider Modes) Microsoft.ContainerService.Data, Microsoft.CustomerLockbox.Data, Microsoft.DataCatalog.Data, Microsoft.KeyVault.Data, Microsoft.Kubernetes.Data, Microsoft.MachineLearningServices.Data, Microsoft.Network.Data and Microsoft.Synapse.Data"
  }
}

variable "metadata" {
  type        = map(any)
  default     = {}
  description = "Metadata for the policy."
}

variable "parameters" {
  type        = map(any)
  default     = {}
  description = "Policy parameters."
}

variable "policy_rule" {
  type = object({
    if = any
    then = object({
      effect = string
    })
  })
  validation {
    condition = contains([
      "deny", "audit", "modify", "denyAction", "append",
      "auditIfNotExists", "deployIfNotExists", "disabled"
    ], var.policy_rule.then.effect)
    error_message = "PolicyEffect must be one of: append, audit, auditIfNotExists, deny, denyAction, deployIfNotExists, disabled, modify"
  }
  description = <<EOT
Azure Policy Rule object. Must follow Microsoft schema:
{
  "if": {
    <condition> | <logical operator> | nested conditions
  },
  "then": {
    "effect": "deny | audit | modify | denyAction | append | auditIfNotExists | deployIfNotExists | disabled"
  }
}
EOT
}

variable "policy_type" {
  type        = string
  default     = "Custom"
  description = "Type of policy."
  validation {
    condition     = contains(["BuiltIn", "Custom", "NotSpecified", "Static"], var.policy_type)
    error_message = "PolicyType must be one of: BuiltIn, Custom, NotSpecified, Static"
  }
}
