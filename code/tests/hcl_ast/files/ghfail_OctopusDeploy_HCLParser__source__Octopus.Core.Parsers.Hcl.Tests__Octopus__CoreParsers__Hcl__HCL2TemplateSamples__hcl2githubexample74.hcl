variable "account_id" {
  type        = string
  description = "The AWS Account ID where the lambda function should be deployed"
}

variable "aws_default_region" {
  type        = string
  default     = "us-east-1"
  description = "The AWS region where the resources will be located"
}

variable "lambda_version" {
  type        = string
  description = "The version of the lambda function to deploy"
}

variable "operations_account_id" {
  type        = string
  description = "The AWS account id for the operations account"
}

variable "profile" {
  type        = string
  default     = "default"
  description = "The AWS profile which terraform will use"
}

variable "log_retention_period" {
  description = "The number of days to retain the logs for in CloudWatch"
  default     = 14
}

variable "role_name" {
  type        = string
  description = "The role which terraform will assume in to the AWS accounts"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to all resources"
  default     = {}
}