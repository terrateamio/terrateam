variable "stream_name" {
  type        = string
  description = "Kinesis Firehose Stream Name"
  default     = "cxcloud"
}

variable "account_id" {
  type        = string
  description = "AWS account ID"
}

variable "region" {
  type        = string
  description = "AWS region"
  default     = "eu-west-1"
}

variable "bucket" {
  type        = string
  description = "S3 bucket for logs"
}

variable "es_arn" {
  type        = string
  description = "Elasticsearch ARN"
}

variable "s3_buffer_size" {
  type        = string
  description = "S3 Buffer Size"
  default     = 10
}

variable "s3_buffer_interval" {
  type        = string
  description = "S3 buffer interval"
  default     = 60
}

variable "s3_compression_format" {
  type        = string
  description = "S3 log compression format"
  default     = "GZIP"
}

variable "es_index_name" {
  type        = string
  description = "Elasticsearch index name"
  default     = "cxcloud"
}

variable "es_type_name" {
  type        = string
  description = "Elasticsearch index type"
  default     = "logs"
}

variable "es_buffering_size" {
  type        = string
  description = "Elasticsearch buffering size"
  default     = 10
}

variable "es_buffering_interval" {
  type        = string
  description = "Elasticsearch buffering interval"
  default     = 60
}

variable "s3_backup_mode" {
  type        = string
  description = "S3 backup mode"
  default     = "AllDocuments"
}

variable "whitelisted_aws_account_arns" {
  type        = list(string)
  description = "Whitelisted AWS ARNs to assume role for Kinesis Firehose access"
}