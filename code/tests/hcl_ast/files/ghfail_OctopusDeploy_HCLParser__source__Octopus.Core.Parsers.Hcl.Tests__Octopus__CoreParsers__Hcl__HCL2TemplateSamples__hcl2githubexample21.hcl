###
# Global
###
variable "region" {
  type = string
}

variable "billing_tag_key" {
  type = string
}

variable "billing_tag_value" {
  type = string
}

###
# Global Secret
###

variable "slack_webhook" {
  type = string
}

###
# AWS Cloud Watch - cloudwatch.tf
###
variable "cloudwatch_log_group_name" {
  type = string
}

###
# AWS ECS - ecs.tf
###
variable "github_sha" {
  type    = string
  default = ""
}

variable "ecs_name" {
  type = string
}

variable "scale_in_cooldown" {
  type    = number
  default = 60
}
variable "scale_out_cooldown" {
  type    = number
  default = 60
}
variable "cpu_scale_metric" {
  type    = number
  default = 60
}
variable "memory_scale_metric" {
  type    = number
  default = 60
}
variable "min_capacity" {
  type    = number
  default = 2
}
variable "max_capacity" {
  type    = number
  default = 10
}

# Task Covid Portal
variable "ecs_covid_portal_name" {
  type = string
}

# Task Covid Portal Secrets

variable "ecs_secret_api_authorization" {
  type = string
}

variable "ecs_secret_api_endpoint" {
  type = string
}

variable "ecs_secret_default_from_email" {
  type = string
}

variable "ecs_secret_invitation_email_template_id_en" {
  type = string
}

variable "ecs_secret_invitation_email_template_id_fr" {
  type = string
}

variable "ecs_secret_password_reset_email_template_id_en" {
  type = string
}

variable "ecs_secret_password_reset_email_template_id_fr" {
  type = string
}

variable "ecs_secret_django_admins" {
  type = string
}

variable "ecs_secret_django_secret_key" {
  type = string
}

variable "ecs_secret_email_host" {
  type = string
}

variable "ecs_secret_email_host_user" {
  type = string
}

variable "ecs_secret_email_host_password" {
  type = string
}

variable "ecs_secret_freshdesk_api_endpoint" {
  type = string
}

variable "ecs_secret_freshdesk_api_key" {
  type = string
}

variable "ecs_secret_freshdesk_product_id" {
  type = string
}

variable "ecs_secret_new_relic_license_key" {
  type = string
}

variable "ecs_secret_notify_api_key" {
  type = string
}

variable "ecs_secret_notify_template_id" {
  type = string
}

# Task Covid Portal Env Vars

variable "django_env" {
  type    = string
  default = "production"
}

variable "django_allowed_hosts" {
  type = string
}

variable "email_backend" {
  type    = string
  default = "'django.core.mail.backends.smtp.EmailBackend'"
}

variable "new_relic_app_name" {
  type    = string
  default = "Terraform Covid Alert Portal"
}

variable "email_port" {
  type    = string
  default = "587"
}

variable "email_use_tls" {
  type    = string
  default = "True"
}

variable "dual_urls" {
  type = string
}




# Covid Portal Scaling

variable "portal_autoscale_enabled" {
  type = bool
}

variable "manual_deploy_enabled" {
  type    = bool
  default = false
}

variable "termination_wait_time_in_minutes" {
  type        = number
  description = "minutes to wait to terminate old deploy"
  default     = 1
}

# Metric provider
variable "metric_provider" {
  type = string
}

# Tracing provider
variable "tracer_provider" {
  type = string
}

###
# AWS VPC - networking.tf
###
variable "vpc_cidr_block" {
  type = string
}

variable "vpc_name" {
  type = string
}

###
# AWS RDS - rds.tf
###
# RDS Subnet Group
variable "rds_db_subnet_group_name" {
  type = string
}

# RDS DB - Key Retrieval/Submission
variable "rds_server_db_name" {
  type = string
}

variable "rds_server_name" {
  type = string
}

variable "rds_server_db_user" {
  type = string
}

variable "rds_server_db_password" {
  type = string
}

variable "rds_server_allocated_storage" {
  type = string
}

variable "rds_server_instance_class" {
  type = string
}

###
# AWS Route53 - route53.tf
###
variable "route53_zone_name" {
  type = string
}
