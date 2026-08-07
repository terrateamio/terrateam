variable "rds_name" {
  type        = string
  default     = "rds"
  description = "RDS instance name"
}

variable "rds_enabled" {
  type        = string
  default     = "false"
  description = "Set to false to prevent the module from creating any resources"
}

# Don't use `root`
# ("MasterUsername root cannot be used as it is a reserved word used by the engine")
variable "rds_admin_user" {
  type        = string
  description = "RDS DB admin user name"
  default     = ""
}

# Must be longer than 8 chars
# ("The parameter MasterUserPassword is not a valid password because it is shorter than 8 characters")
variable "rds_admin_password" {
  type        = string
  description = "RDS DB password for the admin user"
  default     = ""
}

# Don't use `default`
# ("DatabaseName default cannot be used as it is a reserved word used by the engine")
variable "rds_db_name" {
  type        = string
  description = "RDS DB database name"
  default     = ""
}

# db.t2.micro is free tier
# https://aws.amazon.com/rds/free
variable "rds_instance_type" {
  type        = string
  default     = "db.t2.micro"
  description = "EC2 instance type for RDS DB"
}

variable "rds_engine" {
  type        = string
  default     = "mysql"
  description = "RDS DB engine"
}

variable "rds_engine_version" {
  type        = string
  default     = "5.6"
  description = "RDS DB engine version"
}

variable "rds_port" {
  type        = string
  default     = "3306"
  description = "RDS DB port"
}

variable "rds_db_parameter_group" {
  type        = string
  default     = "mysql5.6"
  description = "RDS DB engine version"
}

variable "rds_snapshot" {
  type        = string
  default     = ""
  description = "Set to a snapshot ID to restore from snapshot"
}

variable "rds_parameter_group_name" {
  type        = string
  default     = ""
  description = "Existing parameter group name to use"
}

variable "rds_multi_az" {
  type        = string
  default     = "false"
  description = "Run instances in multiple az"
}

variable "rds_storage_type" {
  type        = string
  default     = "gp2"
  description = "Storage type"
}

variable "rds_storage_size" {
  type        = string
  default     = "20"
  description = "Storage size"
}

variable "rds_storage_encrypted" {
  type        = string
  default     = "true"
  description = "Set true to encrypt storage"
}

variable "rds_auto_minor_version_upgrade" {
  type        = string
  default     = "false"
  description = "Allow automated minor version upgrade (e.g. from Postgres 9.5.3 to Postgres 9.5.4)"
}

variable "rds_allow_major_version_upgrade" {
  type        = string
  default     = "false"
  description = "Allow major version upgrade"
}

variable "rds_apply_immediately" {
  type        = string
  default     = "true"
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"
}

variable "rds_skip_final_snapshot" {
  type        = string
  default     = "false"
  description = "If true (default), no snapshot will be made before deleting DB"
}

variable "rds_backup_retention_period" {
  type        = string
  default     = "7"
  description = "Backup retention period in days. Must be > 0 to enable backups"
}

variable "rds_backup_window" {
  type        = string
  default     = "22:00-03:00"
  description = "When AWS can perform DB snapshots, can't overlap with maintenance window"
}

resource "random_pet" "rds_db_name" {
  count     = local.rds_enabled ? 1 : 0
  separator = "_"
}

resource "random_string" "rds_admin_user" {
  count   = local.rds_enabled ? 1 : 0
  length  = 8
  special = false
  number  = false
}

resource "random_string" "rds_admin_password" {
  count   = local.rds_enabled ? 1 : 0
  length  = 16
  special = true
}

locals {
  rds_enabled        = var.rds_enabled == "true"
  rds_admin_user     = length(var.rds_admin_user) > 0 ? var.rds_admin_user : join("", random_string.rds_admin_user.*.result)
  rds_admin_password = length(var.rds_admin_password) > 0 ? var.rds_admin_password : join("", random_string.rds_admin_password.*.result)
  rds_db_name        = join("", random_pet.rds_db_name.*.id)
}

module "rds" {
  source                      = "git::https://github.com/cloudposse/terraform-aws-rds.git?ref=tags/0.4.4"
  enabled                     = var.rds_enabled
  namespace                   = var.namespace
  stage                       = var.stage
  name                        = var.rds_name
  dns_zone_id                 = local.zone_id
  host_name                   = var.rds_name
  security_group_ids          = ["${module.kops_metadata.nodes_security_group_id}"]
  database_name               = local.rds_db_name
  database_user               = local.rds_admin_user
  database_password           = local.rds_admin_password
  database_port               = var.rds_port
  multi_az                    = var.rds_multi_az
  storage_type                = var.rds_storage_type
  allocated_storage           = var.rds_storage_size
  storage_encrypted           = var.rds_storage_encrypted
  engine                      = var.rds_engine
  engine_version              = var.rds_engine_version
  instance_class              = var.rds_instance_type
  db_parameter_group          = var.rds_db_parameter_group
  parameter_group_name        = var.rds_parameter_group_name
  publicly_accessible         = "false"
  subnet_ids                  = ["${module.subnets.private_subnet_ids}"]
  vpc_id                      = module.vpc.vpc_id
  snapshot_identifier         = var.rds_snapshot
  auto_minor_version_upgrade  = var.rds_auto_minor_version_upgrade
  allow_major_version_upgrade = var.rds_allow_major_version_upgrade
  apply_immediately           = var.rds_apply_immediately
  skip_final_snapshot         = var.rds_skip_final_snapshot
  copy_tags_to_snapshot       = "true"
  backup_retention_period     = var.rds_backup_retention_period
  backup_window               = var.rds_backup_window
}

resource "aws_ssm_parameter" "rds_db_name" {
  count       = local.rds_enabled ? 1 : 0
  name        = format(var.chamber_parameter_name, local.chamber_service, "rds_db_name")
  value       = local.rds_db_name
  description = "RDS Database Name"
  type        = "String"
  overwrite   = "true"
}

resource "aws_ssm_parameter" "rds_admin_username" {
  count       = local.rds_enabled ? 1 : 0
  name        = format(var.chamber_parameter_name, local.chamber_service, "rds_admin_username")
  value       = local.rds_admin_user
  description = "RDS Username for the admin DB user"
  type        = "String"
  overwrite   = "true"
}

resource "aws_ssm_parameter" "rds_admin_password" {
  count       = local.rds_enabled ? 1 : 0
  name        = format(var.chamber_parameter_name, local.chamber_service, "rds_admin_password")
  value       = local.rds_admin_password
  description = "RDS Password for the admin DB user"
  type        = "String"
  overwrite   = "true"
}

resource "aws_ssm_parameter" "rds_hostname" {
  count       = local.rds_enabled ? 1 : 0
  name        = format(var.chamber_parameter_name, local.chamber_service, "rds_hostname")
  value       = module.rds.hostname
  description = "RDS hostname"
  type        = "String"
  overwrite   = "true"
}

resource "aws_ssm_parameter" "rds_port" {
  count       = local.rds_enabled ? 1 : 0
  name        = format(var.chamber_parameter_name, local.chamber_service, "rds_port")
  value       = var.rds_port
  description = "RDS port"
  type        = "String"
  overwrite   = "true"
}

output "rds_instance_id" {
  value       = module.rds.instance_id
  description = "RDS ID of the instance"
}

output "rds_instance_address" {
  value       = module.rds.instance_address
  description = "RDS address of the instance"
}

output "rds_instance_endpoint" {
  value       = module.rds.instance_endpoint
  description = "RDS DNS Endpoint of the instance"
}

output "rds_port" {
  value       = local.rds_enabled ? var.rds_port : local.null
  description = "RDS port"
}

output "rds_db_name" {
  value       = local.rds_enabled ? local.rds_db_name : local.null
  description = "RDS db name"
}

output "rds_admin_user" {
  value       = local.rds_enabled ? local.rds_admin_user : local.null
  description = "RDS admin user name"
}

output "rds_admin_password" {
  value       = local.rds_enabled ? local.rds_admin_password : local.null
  description = "RDS admin password"
}

output "rds_hostname" {
  value       = module.rds.hostname
  description = "RDS host name of the instance"
}
