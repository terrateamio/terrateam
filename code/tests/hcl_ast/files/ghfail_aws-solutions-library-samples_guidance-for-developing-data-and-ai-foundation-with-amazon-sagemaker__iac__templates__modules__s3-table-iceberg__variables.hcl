// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "NAMESPACE" {
  
  description = "The namespace to hold the table, similar to a schema name"
}

variable "BUCKET_ARN" {

    description = "The S3 table bucket ARN"
}

variable "TABLE_NAME" {

    description = "The table name"
}

variable "FIELDS" {

  description = "The fields used to define the table schema"
  type = list(object({
    name     = string
    type     = string
    required = bool
  }))

  validation {
    condition = alltrue([
      for field in var.FIELDS :
      can(regex("^[a-zA-Z_][a-zA-Z0-9_]*$", field.name))
    ])
    error_message = "Field names must start with a letter or underscore and can only contain letters, numbers, and underscores."
  }

  validation {
    condition = alltrue([
      for field in var.FIELDS :
      contains(["string", "long", "int", "double", "boolean", "timestamp", "date", "binary"], field.type) ||
      can(regex("^decimal\\(\\d+,\\d+\\)$", field.type))
    ])
    error_message = "Invalid field type specified. Allowed types are: string, long, int, double, boolean, timestamp, date, binary, or decimal(precision,scale)."
  }
}


