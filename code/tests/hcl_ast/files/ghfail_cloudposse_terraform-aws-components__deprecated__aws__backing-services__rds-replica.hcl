variable "rds_replica_name" {
  type        = string
  default     = "rds-replica"
  description = "RDS instance name"
}

variable "rds_replica_enabled" {
  type        = string
  default     = "false"
  description = "Set to false to prevent the module from creating any resources"
}

variable "rds_replica_replicate_source_db" {
  type        = string
  description = "Specifies that this resource is a Replicate database, and to use this value as the source database. This correlates to the identifier of another Amazon RDS Database to replicate. Note that if you are creating a cross-region replica of an encrypted database you will also need to specify a `kms_key_id`."
  default     = "changeme"
}

variable "rds_replica_kms_key_id" {
  type        = string
  description = "The ARN for the KMS encryption key. If creating an encrypted replica, set this to the destination KMS ARN."
  default     = ""
}

# db.t2.micro is free tier
# https://aws.amazon.com/rds/free
variable "rds_replica_instance_type" {
  type        = string
  default     = "db.t2.micro"
  description = "EC2 instance type for RDS DB"
}

variable "rds_replica_port" {
  type        = string
  default     = "3306"
  description = "RDS DB port"
}

variable "rds_replica_snapshot" {
  type        = string
  default     = ""
  description = "Set to a snapshot ID to restore from snapshot"
}

variable "rds_replica_multi_az" {
  type        = string
  default     = "false"
  description = "Run instances in multiple az"
}

variable "rds_replica_storage_type" {
  type        = string
  default     = "gp2"
  description = "Storage type"
}

variable "rds_replica_storage_size" {
  type        = string
  default     = "20"
  description = "Storage size in Gb"
}

variable "rds_replica_storage_encrypted" {
  type        = string
  default     = "true"
  description = "Set to true to encrypt storage"
}

variable "rds_replica_auto_minor_version_upgrade" {
  type        = string
  default     = "true"
  description = "Allow automated minor version upgrade (e.g. from Postgres 9.5.3 to Postgres 9.5.4)"
}

variable "rds_replica_allow_major_version_upgrade" {
  type        = string
  default     = "false"
  description = "Allow major version upgrade"
}

variable "rds_replica_apply_immediately" {
  type        = string
  default     = "true"
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"
}

variable "rds_replica_skip_final_snapshot" {
  type        = string
  default     = "false"
  description = "If true (default), no snapshot will be made before deleting DB"
}

variable "rds_replica_backup_retention_period" {
  type        = string
  default     = "7"
  description = "Backup retention period in days. Must be > 0 to enable backups"
}

variable "rds_replica_backup_window" {
  type        = string
  default     = "22:00-03:00"
  description = "When AWS can perform DB snapshots, can't overlap with maintenance window"
}

locals {
  rds_replica_enabled = var.rds_replica_enabled == "true"
}

module "rds_replica" {
  source                      = "git::https://github.com/cloudposse/terraform-aws-rds-replica.git?ref=tags/0.1.0"
  enabled                     = var.rds_replica_enabled
  namespace                   = var.namespace
  stage                       = var.stage
  name                        = var.rds_replica_name
  kms_key_id                  = var.rds_replica_kms_key_id
  replicate_source_db         = var.rds_replica_replicate_source_db
  dns_zone_id                 = local.zone_id
  host_name                   = var.rds_replica_name
  security_group_ids          = ["${module.kops_metadata.nodes_security_group_id}"]
  database_port               = var.rds_replica_port
  multi_az                    = var.rds_replica_multi_az
  storage_type                = var.rds_replica_storage_type
  storage_encrypted           = var.rds_replica_storage_encrypted
  instance_class              = var.rds_replica_instance_type
  publicly_accessible         = "false"
  subnet_ids                  = ["${module.subnets.private_subnet_ids}"]
  vpc_id                      = module.vpc.vpc_id
  snapshot_identifier         = var.rds_replica_snapshot
  auto_minor_version_upgrade  = var.rds_replica_auto_minor_version_upgrade
  allow_major_version_upgrade = var.rds_replica_allow_major_version_upgrade
  apply_immediately           = var.rds_replica_apply_immediately
  skip_final_snapshot         = var.rds_replica_skip_final_snapshot
  copy_tags_to_snapshot       = "true"
  backup_retention_period     = var.rds_replica_backup_retention_period
  backup_window               = var.rds_replica_backup_window
}

resource "aws_ssm_parameter" "rds_replica_hostname" {
  count       = local.rds_replica_enabled ? 1 : 0
  name        = format(var.chamber_parameter_name, local.chamber_service, "rds_replica_hostname")
  value       = module.rds_replica.hostname
  description = "RDS replica hostname"
  type        = "String"
  overwrite   = "true"
}

resource "aws_ssm_parameter" "rds_replica_port" {
  count       = local.rds_replica_enabled ? 1 : 0
  name        = format(var.chamber_parameter_name, local.chamber_service, "rds_replica_port")
  value       = var.rds_replica_port
  description = "RDS replica port"
  type        = "String"
  overwrite   = "true"
}

output "rds_replica_instance_id" {
  value       = module.rds_replica.instance_id
  description = "RDS replica ID of the instance"
}

output "rds_replica_instance_address" {
  value       = module.rds_replica.instance_address
  description = "RDS replica address of the instance"
}

output "rds_replica_instance_endpoint" {
  value       = module.rds_replica.instance_endpoint
  description = "RDS replica DNS Endpoint of the instance"
}

output "rds_replica_port" {
  value       = local.rds_replica_enabled ? var.rds_replica_port : local.null
  description = "RDS replica port"
}

output "rds_replica_hostname" {
  value       = module.rds_replica.hostname
  description = "RDS replica host name of the instance"
}
