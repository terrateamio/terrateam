# -----------------------------------------------
# EC2 Docker Workload Module - Variables
# -----------------------------------------------

# -----------------------------------------------
# Required Variables
# -----------------------------------------------

variable "solution_name" {
  description = "Solution name for resource naming and discovery"
  type        = string

  validation {
    condition     = length(var.solution_name) <= 16 && can(regex("^([a-z0-9])+(?:-[a-z0-9]+)*$", var.solution_name))
    error_message = "Only max. 16 lower-case alphanumeric characters and dashes in between are allowed."
  }
}

variable "instance_name" {
  description = "Name of the workload (e.g., postgres, redis, custom-app). Used for resource naming and discovery."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.instance_name))
    error_message = "Must start with lowercase alphanumeric, contain only lowercase alphanumeric and dashes, and end with alphanumeric."
  }
}

variable "docker_image_uri" {
  description = "Docker image URI to run. Examples: 'postgres:15', 'nginx:latest', '123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:v1.0'"
  type        = string
}

# -----------------------------------------------
# Network Variables
# -----------------------------------------------

variable "security_group_ids" {
  description = "List of security group IDs to attach. If empty, a default security group will be created."
  type        = list(string)
  default     = []
}

variable "enable_bastion_access" {
  description = "Allow bidirectional traffic with bastion host on mapped ports"
  type        = bool
  default     = false
}

variable "enable_ecs_access" {
  description = "Allow bidirectional traffic with ECS tasks on mapped ports"
  type        = bool
  default     = true
}

variable "enable_loadbalancer_access" {
  description = "Allow ingress from load balancer on mapped ports"
  type        = bool
  default     = false
}

variable "enable_internal_dns" {
  description = "Create DNS A records for service discovery via internal hostname. Zone is managed by Terra3 base module."
  type        = bool
  default     = true
}

variable "internal_dns_workload_name" {
  description = "DNS workload name used for A record creation. Final DNS name will be '{internal_dns_workload_name}.internal.{solution_name}.local' (zone name managed by base module)."
  type        = string
  default     = ""
}

# -----------------------------------------------
# Container Configuration
# -----------------------------------------------

variable "port_mappings" {
  description = "List of port mappings. Each mapping specifies containerPort, hostPort, and protocol."
  type = list(object({
    containerPort = number
    hostPort      = number
    protocol      = string
  }))

  validation {
    condition = alltrue([
      for pm in var.port_mappings :
      pm.containerPort > 0 && pm.containerPort <= 65535 &&
      pm.hostPort > 0 && pm.hostPort <= 65535 &&
      contains(["tcp", "udp"], pm.protocol)
    ])
    error_message = "All ports must be valid (1-65535) and protocol must be 'tcp' or 'udp'."
  }
}

variable "environment_variables" {
  description = "Environment variables to pass to the Docker container as a map of key-value pairs."
  type        = map(string)
  default     = {}
}

variable "map_secrets" {
  description = "Map of environment variable names to secret ARNs. Supports both SSM Parameter Store (arn:aws:ssm:...) and AWS Secrets Manager (arn:aws:secretsmanager:...) secrets. Secrets are fetched at runtime and injected as environment variables."
  type        = map(string)
  default     = {}
}

variable "ebs_volumes" {
  description = "List of EBS volumes to create and mount to the Docker container."
  type = list(object({
    device_name           = optional(string, "/dev/sdf")
    size                  = number
    volume_type           = optional(string, "gp3")
    mount_path            = string
    delete_on_termination = optional(bool, false)
  }))
  default = []

  validation {
    condition = alltrue([
      for vol in var.ebs_volumes :
      vol.size > 0 && vol.size <= 16384 &&
      contains(["gp2", "gp3", "io1", "io2", "st1", "sc1"], vol.volume_type) &&
      vol.mount_path != "" &&
      startswith(vol.device_name, "/dev/")
    ])
    error_message = "Volume size must be 1-16384 GB, volume_type must be valid, mount_path must not be empty, and device_name must start with /dev/."
  }
}

variable "ebs_volume_availability_zone" {
  description = "Availability zone for EBS volume creation. Must match the AZ where the EC2 instance will be launched. Required to prevent EBS volume replacement on re-apply."
  type        = string
}

# -----------------------------------------------
# Instance Configuration
# -----------------------------------------------

variable "instance_type" {
  description = "EC2 instance type for the workload. Default is t4g.nano (ARM-based, cost-effective)."
  type        = string
  default     = "t4g.nano"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB for the EC2 instance."
  type        = number
  default     = 50

  validation {
    condition     = var.root_volume_size > 0 && var.root_volume_size <= 16384
    error_message = "Root volume size must be between 1 and 16384 GB."
  }
}

variable "root_volume_type" {
  description = "Root EBS volume type."
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.root_volume_type)
    error_message = "Root volume type must be gp2, gp3, io1, or io2."
  }
}

# -----------------------------------------------
# IAM & Permissions
# -----------------------------------------------

variable "enable_ecr_access" {
  description = "Allow EC2 instance to pull Docker images from ECR repositories."
  type        = bool
  default     = false
}

variable "additional_iam_policy_arns" {
  description = "List of additional IAM policy ARNs to attach to the instance role."
  type        = list(string)
  default     = []
}

# -----------------------------------------------
# ASG Configuration
# -----------------------------------------------

variable "min_healthy_percentage" {
  description = "Minimum percentage of healthy instances during rolling update (0-100)."
  type        = number
  default     = 0

  validation {
    condition     = var.min_healthy_percentage >= 0 && var.min_healthy_percentage <= 100
    error_message = "Min healthy percentage must be between 0 and 100."
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days. 0 means never expire."
  type        = number
  default     = 7

  validation {
    condition     = var.log_retention_days >= 0 && (var.log_retention_days == 0 || contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days))
    error_message = "Log retention must be 0 or one of: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653 days."
  }
}

# -----------------------------------------------
# Tagging
# -----------------------------------------------

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------
# Backup Configuration
# -----------------------------------------------

variable "enable_backup" {
  description = "Enable automated backups for EBS volumes using AWS Backup service"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Number of days to retain EBS snapshots in AWS Backup vault"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 3650
    error_message = "Backup retention must be between 1 and 3650 days."
  }
}

variable "backup_schedule" {
  description = "Backup schedule in AWS EventBridge cron format (UTC). Default: daily at 2 AM UTC"
  type        = string
  default     = "cron(0 2 ? * * *)"
}

# -----------------------------------------------
# ALB Integration
# -----------------------------------------------

variable "enable_load_balancer" {
  description = "Enable ALB integration to expose the service through the load balancer"
  type        = bool
  default     = false
}

variable "internal_service" {
  description = "If true, service is not exposed via ALB (even if enable_load_balancer is true)"
  type        = bool
  default     = false
}

variable "path_mapping" {
  description = "ALB path pattern for routing (e.g., '/postgres/*'). Only used if enable_load_balancer is true"
  type        = string
  default     = "/*"
}

variable "listener_rule_prio" {
  description = "ALB listener rule priority (must be unique across all rules). Only used if enable_load_balancer is true"
  type        = number
  default     = 1000

  validation {
    condition     = var.listener_rule_prio > 0 && var.listener_rule_prio < 50000
    error_message = "Listener rule priority must be between 1 and 49999."
  }
}

variable "lb_healthcheck_port" {
  description = "Port for ALB health checks (defaults to hostPort of first port_mapping if enable_load_balancer is true)"
  type        = string
  default     = "traffic-port"
}

variable "lb_healthcheck_interval" {
  description = "ALB health check interval in seconds"
  type        = number
  default     = 30

  validation {
    condition     = var.lb_healthcheck_interval >= 5 && var.lb_healthcheck_interval <= 300
    error_message = "Health check interval must be between 5 and 300 seconds."
  }
}

variable "lb_healthcheck_timeout" {
  description = "ALB health check timeout in seconds"
  type        = number
  default     = 5

  validation {
    condition     = var.lb_healthcheck_timeout >= 2 && var.lb_healthcheck_timeout <= 120
    error_message = "Health check timeout must be between 2 and 120 seconds."
  }
}

variable "lb_healthcheck_healthy_threshold" {
  description = "Number of consecutive health checks to mark instance healthy"
  type        = number
  default     = 2

  validation {
    condition     = var.lb_healthcheck_healthy_threshold >= 2 && var.lb_healthcheck_healthy_threshold <= 10
    error_message = "Healthy threshold must be between 2 and 10."
  }
}

variable "lb_healthcheck_unhealthy_threshold" {
  description = "Number of consecutive health checks to mark instance unhealthy"
  type        = number
  default     = 2

  validation {
    condition     = var.lb_healthcheck_unhealthy_threshold >= 2 && var.lb_healthcheck_unhealthy_threshold <= 10
    error_message = "Unhealthy threshold must be between 2 and 10."
  }
}

variable "deregistration_delay" {
  description = "Time (in seconds) to wait for connections to drain before forcefully closing them"
  type        = number
  default     = 30

  validation {
    condition     = var.deregistration_delay >= 0 && var.deregistration_delay <= 3600
    error_message = "Deregistration delay must be between 0 and 3600 seconds."
  }
}

# -----------------------------------------------
# SSM & Health Checks
# -----------------------------------------------

variable "health_check_grace_period" {
  description = "Time (in seconds) to wait for the instance to become healthy before starting health checks. Increase if SSM Agent takes longer to initialize."
  type        = number
  default     = 600

  validation {
    condition     = var.health_check_grace_period >= 60 && var.health_check_grace_period <= 3600
    error_message = "Health check grace period must be between 60 and 3600 seconds."
  }
}
