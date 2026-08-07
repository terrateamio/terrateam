#------------------------------------------------------------------------------
# Misc
#------------------------------------------------------------------------------
variable "name_prefix" {
  description = "Name prefix for resources on AWS"
}

variable "enable_module" {
  description = "(Optional) Boolean variable to enable or disable the whole module. Defaults to true."
  type        = bool
  default     = true
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Resource tags"
}

#------------------------------------------------------------------------------
# AWS Networking
#------------------------------------------------------------------------------
variable "vpc_id" {
  description = "ID of the VPC"
}

#------------------------------------------------------------------------------
# AWS ECS Container Definition Variables
#------------------------------------------------------------------------------
variable "additional_containers" {
  description = "Additional container definitions (sidecars) to use for the task."
  default     = []
  type        = any #cloudposse/ecs-container-definition/aws
}

variable "container_name" {
  type        = string
  description = "The name of the container. Up to 255 characters ([a-z], [A-Z], [0-9], -, _ allowed)"
}

variable "container_image" {
  type        = string
  description = "The image used to start the container. Images in the Docker Hub registry available by default"
}

variable "container_memory" {
  type        = number
  description = "(Optional) The amount of memory (in MiB) to allow the container to use. This is a hard limit, if the container attempts to exceed the container_memory, the container is killed. This field is optional for Fargate launch type and the total amount of container_memory of all containers in a task will need to be lower than the task memory value"
  default     = 4096 # 4 GB
}

variable "container_memory_reservation" {
  type        = number
  description = "(Optional) The amount of memory (in MiB) to reserve for the container. If container needs to exceed this threshold, it can do so up to the set container_memory hard limit"
  default     = 2048 # 2 GB
}

variable "container_definition_overrides" {
  type        = map(any)
  description = "Container definition overrides which allows for extra keys or overriding existing keys."
  default     = {}
}

variable "port_mappings" {
  description = "The port mappings to configure for the container. This is a list of maps. Each map should contain \"containerPort\", \"hostPort\", and \"protocol\", where \"protocol\" is one of \"tcp\" or \"udp\". If using containers in a task with the awsvpc or host network mode, the hostPort can either be left blank or set to the same value as the containerPort"
  type = list(object({
    containerPort = number
    hostPort      = number
    protocol      = string
  }))
  default = [
    {
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }
  ]
}

# https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_HealthCheck.html
variable "healthcheck" {
  description = "(Optional) A map containing command (string), timeout, interval (duration in seconds), retries (1-10, number of times to retry before marking container unhealthy), and startPeriod (0-300, optional grace period to wait, in seconds, before failed healthchecks count toward retries)"
  type = object({
    command     = list(string)
    retries     = number
    timeout     = number
    interval    = number
    startPeriod = number
  })
  default = null
}

variable "container_cpu" {
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html#fargate-task-defs
  type        = number
  description = "(Optional) The number of cpu units to reserve for the container. This is optional for tasks using Fargate launch type and the total amount of container_cpu of all containers in a task will need to be lower than the task-level cpu value"
  default     = 1024 # 1 vCPU
}

variable "essential" {
  type        = bool
  description = "Determines whether all other containers in a task are stopped, if this container fails or stops for any reason. Due to how Terraform type casts booleans in json it is required to double quote this value"
  default     = true
}

variable "entrypoint" {
  type        = list(string)
  description = "The entry point that is passed to the container"
  default     = []
}

variable "command" {
  type        = list(string)
  description = "The command that is passed to the container"
  default     = []
}

variable "working_directory" {
  type        = string
  description = "The working directory to run commands inside the container"
  default     = null
}

variable "environment" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "The environment variables to pass to the container. This is a list of maps. map_environment overrides environment"
  default     = []
}

variable "extra_hosts" {
  type = list(object({
    ipAddress = string
    hostname  = string
  }))
  description = "A list of hostnames and IP address mappings to append to the /etc/hosts file on the container. This is a list of maps"
  default     = []
}

variable "map_environment" {
  type        = map(string)
  description = "The environment variables to pass to the container. This is a map of string: {key: value}. map_environment overrides environment"
  default     = null
}

# https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_EnvironmentFile.html
variable "environment_files" {
  type = list(object({
    value = string
    type  = string
  }))
  description = "One or more files containing the environment variables to pass to the container. This maps to the --env-file option to docker run. The file must be hosted in Amazon S3. This option is only available to tasks using the EC2 launch type. This is a list of maps"
  default     = []
}

variable "secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  description = "The secrets to pass to the container. This is a list of maps"
  default     = []
}

variable "readonly_root_filesystem" {
  type        = bool
  description = "Determines whether a container is given read-only access to its root filesystem. Due to how Terraform type casts booleans in json it is required to double quote this value"
  default     = false
}

# https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LinuxParameters.html
variable "linux_parameters" {
  type = object({
    capabilities = object({
      add  = list(string)
      drop = list(string)
    })
    devices = list(object({
      containerPath = string
      hostPath      = string
      permissions   = list(string)
    }))
    initProcessEnabled = bool
    maxSwap            = number
    sharedMemorySize   = number
    swappiness         = number
    tmpfs = list(object({
      containerPath = string
      mountOptions  = list(string)
      size          = number
    }))
  })
  description = "Linux-specific modifications that are applied to the container, such as Linux kernel capabilities. For more details, see https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LinuxParameters.html"
  default     = null
}

# https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html
variable "log_configuration" {
  type        = any
  description = "Log configuration options to send to a custom log driver for the container. For more details, see https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html"
  default     = null
}

# https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_FirelensConfiguration.html
variable "firelens_configuration" {
  type = object({
    type    = string
    options = map(string)
  })
  description = "The FireLens configuration for the container. This is used to specify and configure a log router for container logs. For more details, see https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_FirelensConfiguration.html"
  default     = null
}

variable "mount_points" {
  type = list(any)

  description = "Container mount points. This is a list of maps, where each map should contain a `containerPath` and `sourceVolume`. The `readOnly` key is optional."
  default     = []
}

variable "dns_servers" {
  type        = list(string)
  description = "Container DNS servers. This is a list of strings specifying the IP addresses of the DNS servers"
  default     = []
}

variable "dns_search_domains" {
  type        = list(string)
  description = "Container DNS search domains. A list of DNS search domains that are presented to the container"
  default     = []
}

variable "ulimits" {
  type = list(object({
    name      = string
    hardLimit = number
    softLimit = number
  }))
  description = "Container ulimit settings. This is a list of maps, where each map should contain \"name\", \"hardLimit\" and \"softLimit\""
  default     = []
}

variable "repository_credentials" {
  type        = map(string)
  description = "Container repository credentials; required when using a private repo.  This map currently supports a single key; \"credentialsParameter\", which should be the ARN of a Secrets Manager's secret holding the credentials"
  default     = null
}

variable "volumes_from" {
  type = list(object({
    sourceContainer = string
    readOnly        = bool
  }))
  description = "A list of VolumesFrom maps which contain \"sourceContainer\" (name of the container that has the volumes to mount) and \"readOnly\" (whether the container can write to the volume)"
  default     = []
}

variable "links" {
  type        = list(string)
  description = "List of container names this container can communicate with without port mappings"
  default     = []
}

variable "user" {
  type        = string
  description = "The user to run as inside the container. Can be any of these formats: user, user:group, uid, uid:gid, user:gid, uid:group. The default (null) will use the container's configured `USER` directive or root if not set."
  default     = null
}

variable "container_depends_on" {
  type = list(object({
    containerName = string
    condition     = string
  }))
  description = "The dependencies defined for container startup and shutdown. A container can contain multiple dependencies. When a dependency is defined for container startup, for container shutdown it is reversed. The condition can be one of START, COMPLETE, SUCCESS or HEALTHY"
  default     = []
}

variable "docker_labels" {
  type        = map(string)
  description = "The configuration options to send to the `docker_labels`"
  default     = null
}

variable "start_timeout" {
  type        = number
  description = "Time duration (in seconds) to wait before giving up on resolving dependencies for a container"
  default     = null
}

variable "stop_timeout" {
  type        = number
  description = "Time duration (in seconds) to wait before the container is forcefully killed if it doesn't exit normally on its own"
  default     = null
}

variable "privileged" {
  type        = bool
  description = "When this variable is `true`, the container is given elevated privileges on the host container instance (similar to the root user). This parameter is not supported for Windows containers or tasks using the Fargate launch type."
  default     = null
}

variable "system_controls" {
  type        = list(map(string))
  description = "A list of namespaced kernel parameters to set in the container, mapping to the --sysctl option to docker run. This is a list of maps: { namespace = \"\", value = \"\"}"
  default     = []
}

variable "hostname" {
  type        = string
  description = "The hostname to use for your container."
  default     = null
}

variable "disable_networking" {
  type        = bool
  description = "When this parameter is true, networking is disabled within the container."
  default     = null
}

variable "interactive" {
  type        = bool
  description = "When this parameter is true, this allows you to deploy containerized applications that require stdin or a tty to be allocated."
  default     = null
}

variable "pseudo_terminal" {
  type        = bool
  description = "When this parameter is true, a TTY is allocated. "
  default     = null
}

variable "docker_security_options" {
  type        = list(string)
  description = "A list of strings to provide custom labels for SELinux and AppArmor multi-level security systems."
  default     = []
}

#------------------------------------------------------------------------------
# AWS ECS Task Definition Variables
#------------------------------------------------------------------------------
variable "permissions_boundary" {
  description = "(Optional) The ARN of the policy that is used to set the permissions boundary for the `ecs_task_execution_role` role."
  type        = string
  default     = null
}

variable "ecs_task_execution_role_custom_policies" {
  description = "(Optional) Custom policies to attach to the ECS task execution role. For example for reading secrets from AWS Systems Manager Parameter Store or Secrets Manager"
  type        = list(string)
  default     = []
}

variable "placement_constraints_task_definition" {
  description = "(Optional) A set of placement constraints rules that are taken into consideration during task placement. Maximum number of placement_constraints is 10. This is a list of maps, where each map should contain \"type\" and \"expression\""
  type        = list(any)
  default     = []
}

variable "proxy_configuration" {
  description = "(Optional) The proxy configuration details for the App Mesh proxy. This is a list of maps, where each map should contain \"container_name\", \"properties\" and \"type\""
  type        = list(any)
  default     = []
}

variable "ephemeral_storage_size" {
  type        = number
  description = "The number of GBs to provision for ephemeral storage on Fargate tasks. Must be greater than or equal to 21 and less than or equal to 200"
  default     = 0

  validation {
    condition     = var.ephemeral_storage_size == 0 || (var.ephemeral_storage_size >= 21 && var.ephemeral_storage_size <= 200)
    error_message = "The ephemeral_storage_size value must be inclusively between 21 and 200."
  }
}

variable "volumes" {
  description = "(Optional) A set of volume blocks that containers in your task may use"
  type = list(object({
    host_path = string
    name      = string
    docker_volume_configuration = list(object({
      autoprovision = bool
      driver        = string
      driver_opts   = map(string)
      labels        = map(string)
      scope         = string
    }))
    efs_volume_configuration = list(object({
      file_system_id          = string
      root_directory          = string
      transit_encryption      = string
      transit_encryption_port = string
      authorization_config = list(object({
        access_point_id = string
        iam             = string
      }))
    }))
  }))
  default = []
}

#------------------------------------------------------------------------------
# AWS ECS SERVICE
#------------------------------------------------------------------------------
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

variable "deployment_controller" {
  description = "(Optional) Deployment controller"
  type        = list(any)
  default = [{
    type = "ECS"
  }]
}

variable "desired_count" {
  description = "(Optional) The number of instances of the task definition to place and keep running. Defaults to 0."
  type        = number
  default     = 1
}

variable "enable_ecs_managed_tags" {
  description = "(Optional) Specifies whether to enable Amazon ECS managed tags for the tasks within the service."
  type        = bool
  default     = false
}

variable "force_new_deployment" {
  description = "(Optional) Enable to force a new task deployment of the service. This can be used to update tasks to use a newer Docker image with same image/tag combination (e.g. myimage:latest), roll Fargate tasks onto a newer platform version, or immediately deploy ordered_placement_strategy and placement_constraints updates."
  default     = false
  type        = bool
}

variable "enable_execute_command" {
  description = "(Optional) Specifies whether to enable Amazon ECS Exec for the tasks within the service."
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

variable "ecs_service_placement_constraints" {
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

variable "enable_autoscaling" {
  description = "(Optional) If true, autoscaling alarms will be created."
  type        = bool
  default     = true
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

variable "wait_for_ready_state" {
  description = "(Optional) If true, Terraform will wait for the service to reach a steady state (like aws ecs wait services-stable) before continuing. Default false."
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# AWS ECS SERVICE network_configuration BLOCK
#------------------------------------------------------------------------------
variable "public_subnets_ids" {
  description = "The public subnets associated with the task or service."
  type        = list(any)
}

variable "private_subnets_ids" {
  description = "The private subnets associated with the task or service."
  type        = list(any)
}

variable "ecs_service_security_groups" {
  description = "(Optional) The security groups associated with the task or service. If you do not specify a security group, the default security group for the VPC is used."
  type        = list(any)
  default     = []
}

variable "assign_public_ip" {
  description = "(Optional) Assign a public IP address to the ENI (Fargate launch type only). If true service will be associated with public subnets. Default false. "
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# APPLICATION LOAD BALANCER
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

variable "lb_waf_web_acl_arn" {
  description = "ARN of a WAFV2 to associate with the ALB"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# APPLICATION LOAD BALANCER LOGS
#------------------------------------------------------------------------------
variable "enable_s3_logs" {
  description = "(Optional) If true, all resources to send LB logs to S3 will be created"
  type        = bool
  default     = true
}

variable "block_s3_bucket_public_access" {
  description = "(Optional) If true, public access to the S3 bucket will be blocked."
  type        = bool
  default     = true
}

variable "enable_s3_bucket_server_side_encryption" {
  description = "(Optional) If true, server side encryption will be applied."
  type        = bool
  default     = true
}

variable "s3_bucket_server_side_encryption_sse_algorithm" {
  description = "(Optional) The server-side encryption algorithm to use. Valid values are AES256 and aws:kms"
  type        = string
  default     = "AES256"
}

variable "s3_bucket_server_side_encryption_key" {
  description = "(Optional) The AWS KMS master key ID used for the SSE-KMS encryption. This can only be used when you set the value of sse_algorithm as aws:kms. The default aws/s3 AWS KMS master key is used if this element is absent while the sse_algorithm is aws:kms."
  type        = string
  default     = null
}

#------------------------------------------------------------------------------
# ACCESS CONTROL TO APPLICATION LOAD BALANCER
#------------------------------------------------------------------------------
variable "lb_http_ports" {
  description = "Map containing objects with two fields, listener_port and the target_group_port to redirect HTTP requests"
  type        = map(any)
  default = {
    default-http = {
      listener_port     = 80
      target_group_port = 80
    }
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
  description = "Map containing objects with two fields, listener_port and the target_group_port to redirect HTTPS requests"
  type        = map(any)
  default = {
    default-https = {
      listener_port     = 443
      target_group_port = 443
    }
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
