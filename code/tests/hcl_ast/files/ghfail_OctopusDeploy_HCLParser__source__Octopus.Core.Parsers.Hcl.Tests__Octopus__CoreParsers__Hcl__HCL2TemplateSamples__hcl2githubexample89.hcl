// Environment variables to be consumed by the lambda function

resource "aws_ssm_parameter" "core_storage_hostname" {
  name        = "core_storage_hostname_${var.environment}"
  type        = "SecureString"
  value       = aws_db_instance.core_storage.address
  description = "Hostname for the core storage"
  overwrite   = "true"

  tags = local.tags
}

resource "aws_ssm_parameter" "core_storage_port" {
  name        = "core_storage_port_${var.environment}"
  type        = "SecureString"
  value       = aws_db_instance.core_storage.port
  description = "Port for the core storage"
  overwrite   = "true"

  tags = local.tags
}

resource "aws_ssm_parameter" "core_storage_username" {
  name        = "core_storage_username_${var.environment}"
  type        = "SecureString"
  value       = aws_db_instance.core_storage.username
  description = "Username for the core storage"
  overwrite   = "true"

  tags = local.tags
}

resource "aws_ssm_parameter" "core_storage_password" {
  name        = "core_storage_password_${var.environment}"
  type        = "SecureString"
  value       = aws_db_instance.core_storage.password
  description = "Password for the core storage"
  overwrite   = "true"

  tags = local.tags
}

resource "aws_ssm_parameter" "core_storage_database" {
  name        = "core_storage_database_${var.environment}"
  type        = "SecureString"
  value       = "postgres"
  description = "Database name for the core storage"
  overwrite   = "true"

  tags = local.tags
}

resource "aws_ssm_parameter" "core_storage_schema" {
  name        = "core_storage_schema_${var.environment}"
  type        = "SecureString"
  value       = "celsus_core"
  description = "Schema name for the core storage"
  overwrite   = "true"

  tags = local.tags
}

resource "aws_ssm_parameter" "contact_storage_hostname" {
  name        = "contact_storage_hostname_${var.environment}"
  type        = "SecureString"
  value       = aws_db_instance.core_storage.address
  description = "Hostname for the contact storage"
  overwrite   = "true"

  tags = local.tags
}

resource "aws_ssm_parameter" "contact_storage_port" {
  name        = "contact_storage_port_${var.environment}"
  type        = "SecureString"
  value       = aws_db_instance.core_storage.port
  description = "Port for the contact storage"
  overwrite   = "true"

  tags = local.tags
}

resource "aws_ssm_parameter" "contact_storage_username" {
  name        = "contact_storage_username_${var.environment}"
  type        = "SecureString"
  value       = aws_db_instance.core_storage.username
  description = "Username for the contact storage"
  overwrite   = "true"

  tags = local.tags
}

resource "aws_ssm_parameter" "contact_storage_password" {
  name        = "contact_storage_password_${var.environment}"
  type        = "SecureString"
  value       = aws_db_instance.core_storage.password
  description = "Password for the contact storage"
  overwrite   = "true"

  tags = local.tags
}

resource "aws_ssm_parameter" "contact_storage_database" {
  name        = "contact_storage_database_${var.environment}"
  type        = "SecureString"
  value       = "postgres"
  description = "Database name for the contact storage"
  overwrite   = "true"

  tags = local.tags
}

resource "aws_ssm_parameter" "contact_storage_schema" {
  name        = "contact_storage_schema_${var.environment}"
  type        = "SecureString"
  value       = "celsus_contacts"
  description = "Schema name for the contact storage"
  overwrite   = "true"

  tags = local.tags
}