#------------------------------------------------------------------------------
# Misc
#------------------------------------------------------------------------------
variable "name_prefix" {
  description = "Name prefix for resources on AWS. Max length is 15 characters."
  type        = string
  validation {
    condition     = length(var.name_prefix) <= 15
    error_message = "The name prefix must be 15 characters or less."
  }
}

#------------------------------------------------------------------------------
# AWS Networking
#------------------------------------------------------------------------------
variable "vpc_id" {
  description = "ID of the VPC"
}

#------------------------------------------------------------------------------
# AWS ECS SERVICE
#------------------------------------------------------------------------------
variable "ecs_cluster_arn" {
  description = "ARN of an ECS cluster"
}

variable "deployment_maximum_percent" {
  description = "(Optional) The upper limit (as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment."
  type        = number
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "(Optional) The lower limit (as a percentage of the service's desiredCount) of the number of running tasks that must remain running and healthy in a service during a deployment."
  type        = number
  default     = 100
}

variable "deployment_circuit_breaker_enabled" {
  description = "(Optional) You can enable the deployment circuit breaker to cause a service deployment to transition to a failed state if tasks are persistently failing to reach RUNNING state or are failing healthcheck."
  type        = bool
  default     = false
}

variable "deployment_circuit_breaker_rollback" {
  description = "(Optional) The optional rollback option causes Amazon ECS to roll back to the last completed deployment upon a deployment failure."
  type        = bool
  default     = false
}

variable "desired_count" {
  description = "(Optional) The number of instances of the task definition to place and keep running. Defaults to 0."
  type        = number
  default     = 1
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Resource tags"
}

variable "enable_ecs_managed_tags" {
  description = "(Optional) Specifies whether to enable Amazon ECS managed tags for the tasks within the service."
  type        = bool
  default     = false
}

variable "health_check_grace_period_seconds" {
  description = "(Optional) Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 2147483647. Only valid for services configured to use load balancers."
  type        = number
  default     = 0
}

variable "ordered_placement_strategy" {
  description = "(Optional) Service level strategy rules that are taken into consideration during task placement. List from top to bottom in order of precedence. The maximum number of ordered_placement_strategy blocks is 5. This is a list of maps where each map should contain \"id\" and \"field\""
  type        = list(any)
  default     = []
}

variable "deployment_controller" {
  description = "(Optional) Deployment controller default: 'ECS'"
  type        = list(any)
  default = [
    {
      type = "ECS"
    }
  ]
}

variable "placement_constraints" {
  type        = list(any)
  description = "(Optional) rules that are taken into consideration during task placement. Maximum number of placement_constraints is 10. This is a list of maps, where each map should contain \"type\" and \"expression\""
  default     = []
}

variable "platform_version" {
  description = "(Optional) The platform version on which to run your service. Defaults to 1.4.0. More information about Fargate platform versions can be found in the AWS ECS User Guide."
  default     = "1.4.0"
}

variable "propagate_tags" {
  description = "(Optional) Specifies whether to propagate the tags from the task definition or the service to the tasks. The valid values are SERVICE and TASK_DEFINITION. Default to SERVICE"
  default     = "SERVICE"
}

variable "service_registries" {
  description = "(Optional) The service discovery registries for the service. The maximum number of service_registries blocks is 1. This is a map that should contain the following fields \"registry_arn\", \"port\", \"container_port\" and \"container_name\""
  type        = map(any)
  default     = {}
}

variable "task_definition_arn" {
  description = "(Optional) The full ARN of the task definition that you want to run in your service."
  default     = ""
  type        = string
}

variable "force_new_deployment" {
  description = "(Optional) Enable to force a new task deployment of the service. This can be used to update tasks to use a newer Docker image with same image/tag combination (e.g. myimage:latest), roll Fargate tasks onto a newer platform version, or immediately deploy ordered_placement_strategy and placement_constraints updates."
  type        = bool
  default     = false
}

variable "enable_execute_command" {
  description = "(Optional) Specifies whether to enable Amazon ECS Exec for the tasks within the service."
  type        = bool
  default     = false
}

variable "wait_for_ready_state" {
  description = "(Optional) If true, Terraform will wait for the service to reach a steady state (like aws ecs wait services-stable) before continuing. Default false."
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# AWS ECS SERVICE network_configuration BLOCK
#------------------------------------------------------------------------------
variable "public_subnets" {
  description = "The public subnets associated with the task or service."
  type        = list(any)
}

variable "private_subnets" {
  description = "The private subnets associated with the task or service."
  type        = list(any)
}

variable "security_groups" {
  description = "(Optional) The security groups associated with the task or service. If you do not specify a security group, the default security group for the VPC is used."
  type        = list(any)
  default     = []
}

variable "assign_public_ip" {
  description = "(Optional) Assign a public IP address to the ENI (Fargate launch type only). If true service will be associated with public subnets. Default false. "
  type        = bool
  default     = false
}

variable "ecs_tasks_sg_allow_egress_to_anywhere" {
  description = "(Optional) If true an egress rule will be created to allow traffic to anywhere (0.0.0.0/0). If false no egress rule will be created. Defaults to true"
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# AWS ECS SERVICE load_balancer BLOCK
#------------------------------------------------------------------------------
variable "container_name" {
  description = "Name of the running container"
}

#------------------------------------------------------------------------------
# AWS ECS SERVICE AUTOSCALING
#------------------------------------------------------------------------------
variable "enable_autoscaling" {
  description = "(Optional) If true, autoscaling alarms will be created."
  type        = bool
  default     = true
}

variable "ecs_cluster_name" {
  description = "(Optional) Name of the ECS cluster. Required only if autoscaling is enabled"
  type        = string
  default     = null
}

variable "max_cpu_threshold" {
  description = "Threshold for max CPU usage"
  default     = "85"
  type        = string
}
variable "min_cpu_threshold" {
  description = "Threshold for min CPU usage"
  default     = "10"
  type        = string
}

variable "max_cpu_evaluation_period" {
  description = "The number of periods over which data is compared to the specified threshold for max cpu metric alarm"
  default     = "3"
  type        = string
}
variable "min_cpu_evaluation_period" {
  description = "The number of periods over which data is compared to the specified threshold for min cpu metric alarm"
  default     = "3"
  type        = string
}

variable "max_cpu_period" {
  description = "The period in seconds over which the specified statistic is applied for max cpu metric alarm"
  default     = "60"
  type        = string
}
variable "min_cpu_period" {
  description = "The period in seconds over which the specified statistic is applied for min cpu metric alarm"
  default     = "60"
  type        = string
}

variable "scale_target_max_capacity" {
  description = "The max capacity of the scalable target"
  default     = 5
  type        = number
}

variable "scale_target_min_capacity" {
  description = "The min capacity of the scalable target"
  default     = 1
  type        = number
}

#------------------------------------------------------------------------------
# AWS LOAD BALANCER
#------------------------------------------------------------------------------
variable "custom_lb_arn" {
  description = "ARN of the Load Balancer to use in the ECS service. If provided, this module will not create a load balancer and will use the one provided in this variable"
  type        = string
  default     = null
}

variable "additional_lbs" {
  default     = {}
  description = "Additional load balancers to add to ECS service"
  type = map(object
    (
      {
        target_group_arn = string
        container_port   = number
      }
    )
  )
}

variable "lb_internal" {
  description = "(Optional) If true, the LB will be internal."
  type        = bool
  default     = false
}

variable "lb_security_groups" {
  description = "(Optional) A list of security group IDs to assign to the LB."
  type        = list(string)
  default     = []
}

variable "lb_drop_invalid_header_fields" {
  description = "(Optional) Indicates whether HTTP headers with header fields that are not valid are removed by the load balancer (true) or routed to targets (false). The default is false. Elastic Load Balancing requires that message header names contain only alphanumeric characters and hyphens."
  type        = bool
  default     = false
}

variable "lb_idle_timeout" {
  description = "(Optional) The time in seconds that the connection is allowed to be idle. Default: 60."
  type        = number
  default     = 60
}

variable "lb_enable_deletion_protection" {
  description = "(Optional) If true, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer. Defaults to false."
  type        = bool
  default     = false
}

variable "lb_enable_cross_zone_load_balancing" {
  description = "(Optional) If true, cross-zone load balancing of the load balancer will be enabled. Defaults to false."
  type        = bool
  default     = false
}

variable "lb_enable_http2" {
  description = "(Optional) Indicates whether HTTP/2 is enabled in the load balancer. Defaults to true."
  type        = bool
  default     = true
}

variable "lb_ip_address_type" {
  description = "(Optional) The type of IP addresses used by the subnets for your load balancer. The possible values are ipv4 and dualstack. Defaults to ipv4"
  type        = string
  default     = "ipv4"
}

variable "waf_web_acl_arn" {
  description = "ARN of a WAFV2 to associate with the ALB"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# ACCESS CONTROL TO APPLICATION LOAD BALANCER
#------------------------------------------------------------------------------
variable "lb_http_ports" {
  description = "Map containing objects to define listeners behaviour based on type field. If type field is `forward`, include listener_port and the target_group_port. For `redirect` type, include listener_port, host, path, port, protocol, query and status_code. For `fixed-response`, include listener_port, content_type, message_body and status_code"
  type = map(object({
    type = optional(string)

    listener_port = number

    target_group_port             = optional(number)
    target_group_protocol         = optional(string, "HTTP")
    target_group_protocol_version = optional(string, "HTTP1") # HTTP1, HTTP2 or GRPC

    # Health check options, overriding default values provided as module variables
    target_group_health_check_enabled             = optional(bool)
    target_group_health_check_interval            = optional(number)
    target_group_health_check_path                = optional(string)
    target_group_health_check_port                = optional(string)
    target_group_health_check_protocol            = optional(string, "HTTP")
    target_group_health_check_timeout             = optional(number)
    target_group_health_check_healthy_threshold   = optional(number)
    target_group_health_check_unhealthy_threshold = optional(number)
    target_group_health_check_matcher             = optional(string)

    host         = optional(string, "#{host}")
    path         = optional(string, "/#{path}")
    port         = optional(string, "#{port}")
    protocol     = optional(string, "#{protocol}")
    query        = optional(string, "#{query}")
    status_code  = optional(string) # Default for `type=redirect`: "HTTP_301". Default for `type=fixed-response`: "200".
    content_type = optional(string, "text/plain")
    message_body = optional(string, "Fixed response content")
  }))
  default = {
    default = {
      type              = "forward"
      listener_port     = 80
      target_group_port = 80
    }
  }
  validation {
    condition     = alltrue([for _, v in var.lb_http_ports : v.type != "forward" || v.target_group_port != null])
    error_message = "target_group_port must be set if type is forward"
  }
  validation {
    condition     = alltrue([for _, v in var.lb_http_ports : (v.type == "redirect" || v.type == "fixed-response") ? v.status_code != null : true])
    error_message = "status_code must be set if type is redirect or fixed-response"
  }
}

variable "lb_http_ingress_cidr_blocks" {
  description = "List of CIDR blocks to allowed to access the Load Balancer through HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "lb_http_ingress_prefix_list_ids" {
  description = "List of prefix list IDs blocks to allowed to access the Load Balancer through HTTP"
  type        = list(string)
  default     = []
}

variable "lb_https_ports" {
  description = "Map containing objects to define listeners behaviour based on type field. If type field is `forward`, include listener_port and the target_group_port. For `redirect` type, include listener_port, host, path, port, protocol, query and status_code. For `fixed-response`, include listener_port, content_type, message_body and status_code"
  type = map(object({
    type = optional(string)

    listener_port = number

    target_group_port             = optional(number)
    target_group_protocol         = optional(string, "HTTP")
    target_group_protocol_version = optional(string, "HTTP1") # HTTP1, HTTP2 or GRPC

    # Health check options, overriding default values provided as module variables
    target_group_health_check_enabled             = optional(bool)
    target_group_health_check_interval            = optional(number)
    target_group_health_check_path                = optional(string)
    target_group_health_check_port                = optional(string)
    target_group_health_check_protocol            = optional(string, "HTTP")
    target_group_health_check_timeout             = optional(number)
    target_group_health_check_healthy_threshold   = optional(number)
    target_group_health_check_unhealthy_threshold = optional(number)
    target_group_health_check_matcher             = optional(string)

    host         = optional(string, "#{host}")
    path         = optional(string, "/#{path}")
    port         = optional(string, "#{port}")
    protocol     = optional(string, "#{protocol}")
    query        = optional(string, "#{query}")
    status_code  = optional(string) # Default for `type=redirect`: "HTTP_301". Default for `type=fixed-response`: "200".
    content_type = optional(string, "text/plain")
    message_body = optional(string, "Fixed response content")
  }))
  default = {
    default-https = {
      type              = "forward"
      listener_port     = 443
      target_group_port = 443
    }
  }
  validation {
    condition     = alltrue([for _, v in var.lb_https_ports : v.type != "forward" || v.target_group_port != null])
    error_message = "target_group_port must be set if type is forward"
  }
  validation {
    condition     = alltrue([for _, v in var.lb_https_ports : (v.type == "redirect" || v.type == "fixed-response") ? v.status_code != null : true])
    error_message = "status_code must be set if type is redirect or fixed-response"
  }
}

variable "lb_https_ingress_cidr_blocks" {
  description = "List of CIDR blocks to allowed to access the Load Balancer through HTTPS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "lb_https_ingress_prefix_list_ids" {
  description = "List of prefix list IDs blocks to allowed to access the Load Balancer through HTTPS"
  type        = list(string)
  default     = []
}

#------------------------------------------------------------------------------
# AWS LOAD BALANCER - Target Groups
#------------------------------------------------------------------------------
variable "lb_deregistration_delay" {
  description = "(Optional) The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds. The default value is 300 seconds."
  type        = number
  default     = 300
}

variable "lb_slow_start" {
  description = "(Optional) The amount time for targets to warm up before the load balancer sends them a full share of requests. The range is 30-900 seconds or 0 to disable. The default value is 0 seconds."
  type        = number
  default     = 0
}

variable "lb_load_balancing_algorithm_type" {
  description = "(Optional) Determines how the load balancer selects targets when routing requests. The value is round_robin or least_outstanding_requests. The default is round_robin."
  type        = string
  default     = "round_robin"
}

variable "lb_stickiness" {
  description = "(Optional) A Stickiness block. Provide three fields. type, the type of sticky sessions. The only current possible value is lb_cookie. cookie_duration, the time period, in seconds, during which requests from a client should be routed to the same target. After this time period expires, the load balancer-generated cookie is considered stale. The range is 1 second to 1 week (604800 seconds). The default value is 1 day (86400 seconds). enabled, boolean to enable / disable stickiness. Default is true."
  type = object({
    type            = string
    cookie_duration = string
    enabled         = bool
  })
  default = {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }
}

variable "lb_target_group_health_check_enabled" {
  description = "(Optional) Indicates whether health checks are enabled. Defaults to true."
  type        = bool
  default     = true
}

variable "lb_target_group_health_check_interval" {
  description = "(Optional) The approximate amount of time, in seconds, between health checks of an individual target. Minimum value 5 seconds, Maximum value 300 seconds. Default 30 seconds."
  type        = number
  default     = 30
}

variable "lb_target_group_health_check_path" {
  description = "The destination for the health check request."
  type        = string
  default     = "/"
}

variable "lb_target_group_health_check_port" {
  description = "(Optional) The port to use to connect with the target. Valid values are either ports 1-65536, or traffic-port. Defaults to traffic-port."
  type        = string
  default     = "traffic-port"
}

variable "lb_target_group_health_check_protocol" {
  description = "(Optional) The protocol the load balancer uses when performing health checks on targets. Valid values are HTTP and HTTPS. Defaults to HTTP."
  type        = string
  default     = "HTTP"
}

variable "lb_target_group_health_check_timeout" {
  description = "(Optional) The amount of time, in seconds, during which no response means a failed health check. The range is 2 to 120 seconds, and the default is 5 seconds."
  type        = number
  default     = 5
}

variable "lb_target_group_health_check_healthy_threshold" {
  description = "(Optional) The number of consecutive health checks successes required before considering an unhealthy target healthy. Defaults to 3."
  type        = number
  default     = 3
}

variable "lb_target_group_health_check_unhealthy_threshold" {
  description = "(Optional) The number of consecutive health check failures required before considering the target unhealthy. Defaults to 3."
  type        = number
  default     = 3
}

variable "lb_target_group_health_check_matcher" {
  description = "The HTTP codes to use when checking for a successful response from a target. You can specify multiple values (for example, \"200,202\") or a range of values (for example, \"200-299\"). Default is 200."
  type        = string
  default     = "200"
}

#------------------------------------------------------------------------------
# AWS LOAD BALANCER - Target Groups
#------------------------------------------------------------------------------
variable "ssl_policy" {
  description = "(Optional) The name of the SSL Policy for the listener. . Required if var.https_ports is set."
  type        = string
  default     = null
}

variable "default_certificate_arn" {
  description = "(Optional) The ARN of the default SSL server certificate. Required if var.https_ports is set."
  type        = string
  default     = null
}

variable "additional_certificates_arn_for_https_listeners" {
  description = "(Optional) List of SSL server certificate ARNs for HTTPS listener. Use it if you need to set additional certificates besides default_certificate_arn"
  type        = list(any)
  default     = []
}

#------------------------------------------------------------------------------
# Load Balancer Logs S3 bucket
#------------------------------------------------------------------------------
variable "enable_s3_logs" {
  description = "(Optional) If true, all LoadBalancer logs will be send to S3.  If true, and log_bucket_id is *not* provided, this module will create the bucket with other provided s3 bucket configuration options"
  type        = bool
  default     = true
}

variable "log_bucket_id" {
  description = "(Optional) if provided, the ID of a previously-defined S3 bucket to send LB logs to."
  type        = string
  default     = null
}


variable "block_s3_bucket_public_access" {
  description = "(Optional) If true, public access to the S3 bucket will be blocked.  Ignored if log_bucket_id is provided."
  type        = bool
  default     = true
}

variable "enable_s3_bucket_server_side_encryption" {
  description = "(Optional) If true, server side encryption will be applied.  Ignored if log_bucket_id is provided."
  type        = bool
  default     = true
}

variable "s3_bucket_server_side_encryption_sse_algorithm" {
  description = "(Optional) The server-side encryption algorithm to use. Valid values are AES256 and aws:kms.  Ignored if log_bucket_id is provided."
  type        = string
  default     = "AES256"
}

variable "s3_bucket_server_side_encryption_key" {
  description = "(Optional) The AWS KMS master key ID used for the SSE-KMS encryption. This can only be used when you set the value of sse_algorithm as aws:kms. The default aws/s3 AWS KMS master key is used if this element is absent while the sse_algorithm is aws:kms.    Ignored if log_bucket_id is provided."
  type        = string
  default     = null
}

variable "access_logs_prefix" {
  description = "(Optional) if access logging to an S3 bucket, this sets a prefix in the bucket beneath which this LB's logs will be organized."
  type        = string
  default     = null
}
