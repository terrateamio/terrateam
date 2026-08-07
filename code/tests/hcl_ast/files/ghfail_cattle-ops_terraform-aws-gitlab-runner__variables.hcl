/*
 * Global variables
 */
variable "vpc_id" {
  description = "The VPC used for the runner and runner workers."
  type        = string
}

variable "subnet_id" {
  description = <<-EOT
    Subnet id used for the Runner and Runner Workers. Must belong to the `vpc_id`. In case the fleet mode is used, multiple subnets for
    the Runner Workers can be provided with runner_worker_docker_machine_instance.subnet_ids.
  EOT
  type        = string
}

variable "kms_key_id" {
  description = "KMS key id to encrypt the resources. Ensure that CloudWatch and Runner/Runner Workers have access to the provided KMS key."
  type        = string
  default     = ""
}

variable "enable_managed_kms_key" {
  description = "Let the module manage a KMS key. Be-aware of the costs of an custom key. Do not specify a `kms_key_id` when `enable_kms` is set to `true`."
  type        = bool
  default     = false
}

variable "kms_managed_alias_name" {
  description = "Alias added to the created KMS key."
  type        = string
  default     = ""
}

variable "kms_managed_deletion_rotation_window_in_days" {
  description = "Key deletion/rotation window for the created KMS key. Set to 0 for no rotation/deletion window."
  type        = number
  default     = 7
}

variable "iam_permissions_boundary" {
  description = "Name of permissions boundary policy to attach to AWS IAM roles"
  type        = string
  default     = ""
}

variable "environment" {
  description = "A name that identifies the environment, used as prefix and for tagging."
  type        = string

  validation {
    condition     = !startswith(var.environment, "runner-")
    error_message = "Environment name cannot begin with 'runner-' because it breaks the naming convention for ssh key pairs within the terminate-agent-hook lambda function."
  }
}

variable "tags" {
  description = "Map of tags that will be added to created resources. By default resources will be tagged with name and environment."
  type        = map(string)
  default     = {}
}

variable "suppressed_tags" {
  description = "List of tag keys which are automatically removed and never added as default tag by the module."
  type        = list(string)
  default     = []
}

variable "security_group_prefix" {
  description = "Set the name prefix and overwrite the `Name` tag for all security groups."
  type        = string
  default     = ""
}

variable "iam_object_prefix" {
  description = "Set the name prefix of all AWS IAM resources."
  type        = string
  default     = ""
}

/*
 * Runner Manager: A manager which creates multiple Runners (only one Runner supported by this module) which in turn creates
 *                 multiple Runner Workers (e.g. docker-machine).
 */
variable "runner_manager" {
  description = <<-EOT
    For details check https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section

    gitlab_check_interval = Number of seconds between checking for available jobs (check_interval)
    maximum_concurrent_jobs = The maximum number of jobs which can be processed by all Runners at the same time (concurrent).
    prometheus_listen_address = Defines an address (<host>:<port>) the Prometheus metrics HTTP server should listen on (listen_address).
    sentry_dsn = Sentry DSN of the project for the Runner Manager to use (uses legacy DSN format) (sentry_dsn)
    connection_max_age = The maximum age of a connection to the Runner Manager (connection_max_age).
  EOT
  type = object({
    gitlab_check_interval     = optional(number, 3)
    maximum_concurrent_jobs   = optional(number, 10)
    prometheus_listen_address = optional(string, "")
    sentry_dsn                = optional(string, "__SENTRY_DSN_REPLACED_BY_USER_DATA__")
    connection_max_age        = optional(string, "15m")
  })
  default = {}
}

/*
 * Runner: The agent that runs the code on the host platform and displays in the UI.
 */
variable "runner_instance" {
  description = <<-EOT
    additional_tags = Map of tags that will be added to the Runner instance.
    collect_autoscaling_metrics = A list of metrics to collect. The allowed values are GroupDesiredCapacity, GroupInServiceCapacity, GroupPendingCapacity, GroupMinSize, GroupMaxSize, GroupInServiceInstances, GroupPendingInstances, GroupStandbyInstances, GroupStandbyCapacity, GroupTerminatingCapacity, GroupTerminatingInstances, GroupTotalCapacity, GroupTotalInstances.
    ebs_optimized = Enable EBS optimization for the Runner instance.
    max_lifetime_seconds = The maximum time a Runner should live before it is killed.
    monitoring = Enable the detailed monitoring on the Runner instance.
    name = Name of the Runner instance.
    name_prefix = Set the name prefix and override the `Name` tag for the Runner instance.
    private_address_only = Restrict the Runner to use private IP addresses only. If this is set to `true` the Runner will use a private IP address only in case the Runner Workers use private addresses only.
    root_device_config = The Runner's root block device configuration. Takes the following keys: `device_name`, `delete_on_termination`, `volume_type`, `volume_size`, `encrypted`, `iops`, `throughput`, `kms_key_id`
    spot_price = By setting a spot price bid price the Runner is created via a spot request. Be aware that spot instances can be stopped by AWS. Choose \"on-demand-price\" to pay up to the current on demand price for the instance type chosen.
    ssm_access = Allows to connect to the Runner via SSM.
    type = EC2 instance type used.
    use_eip = Assigns an EIP to the Runner.
  EOT
  type = object({
    additional_tags             = optional(map(string))
    collect_autoscaling_metrics = optional(list(string), null)
    ebs_optimized               = optional(bool, true)
    max_lifetime_seconds        = optional(number, null)
    monitoring                  = optional(bool, true)
    name                        = string
    name_prefix                 = optional(string)
    private_address_only        = optional(bool, true)
    root_device_config          = optional(map(string), {})
    spot_price                  = optional(string, null)
    ssm_access                  = optional(bool, false)
    type                        = optional(string, "t3.micro")
    use_eip                     = optional(bool, false)
  })
  default = {
    name = "gitlab-runner"
  }
}

variable "runner_ami_filter" {
  description = "List of maps used to create the AMI filter for the Runner AMI. Must resolve to an Amazon Linux 1, 2 or 2023 image."
  type        = map(list(string))

  default = {
    name = ["al2023-ami-2023*-x86_64"]
  }
}

variable "runner_ami_owners" {
  description = "The list of owners used to select the AMI of the Runner instance."
  type        = list(string)
  default     = ["amazon"]
}

variable "runner_ami_id" {
  description = "The AMI ID of the Runner instance."
  type        = string
  default     = ""
}

variable "runner_networking" {
  description = <<-EOT
    allow_incoming_ping = Allow ICMP Ping to the Runner. Specify `allow_incoming_ping_security_group_ids` too!
    allow_incoming_ping_security_group_ids = A list of security group ids that are allowed to ping the Runner.
    security_group_description = A description for the Runner's security group
    security_group_ids = IDs of security groups to add to the Runner.
  EOT
  type = object({
    allow_incoming_ping                    = optional(bool, false)
    allow_incoming_ping_security_group_ids = optional(list(string), [])
    security_group_description             = optional(string, "A security group containing gitlab-runner agent instances")
    security_group_ids                     = optional(list(string), [])
  })
  default = {}
}

variable "runner_ingress_rules" {
  description = "Map of Ingress rules for the Runner Manager security group."
  type = map(object({
    from_port       = optional(number, null)
    to_port         = optional(number, null)
    protocol        = string
    description     = string
    cidr_block      = optional(string, null)
    ipv6_cidr_block = optional(string, null)
    prefix_list_id  = optional(string, null)
    security_group  = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for rule in values(var.runner_ingress_rules) :
      contains(["-1", "tcp", "udp", "icmp", "icmpv6"], rule.protocol)
    ])
    error_message = "Protocol must be '-1', 'tcp', 'udp', 'icmp', or 'icmpv6'."
  }

  validation {
    condition = alltrue([
      for rule in values(var.runner_ingress_rules) :
      (rule.cidr_block != null) ||
      (rule.ipv6_cidr_block != null) ||
      (rule.prefix_list_id != null) ||
      (rule.security_group != null)
    ])
    error_message = "At least one destination must be specified."
  }
}

variable "runner_egress_rules" {
  description = "Map of Egress rules for the Runner Manager security group."
  type = map(object({
    from_port       = optional(number, null)
    to_port         = optional(number, null)
    protocol        = string
    description     = string
    cidr_block      = optional(string, null)
    ipv6_cidr_block = optional(string, null)
    prefix_list_id  = optional(string, null)
    security_group  = optional(string, null)
  }))
  default = {
    allow_https_ipv4 = {
      cidr_block  = "0.0.0.0/0"
      from_port   = 443
      protocol    = "tcp"
      to_port     = 443
      description = "Allow HTTPS egress traffic"
    },
    allow_https_ipv6 = {
      ipv6_cidr_block = "::/0"
      from_port       = 443
      protocol        = "tcp"
      to_port         = 443
      description     = "Allow HTTPS egress traffic (IPv6)"
    }
  }

  validation {
    condition = alltrue([
      for rule in values(var.runner_egress_rules) :
      contains(["-1", "tcp", "udp", "icmp", "icmpv6"], rule.protocol)
    ])
    error_message = "Protocol must be '-1', 'tcp', 'udp', 'icmp', or 'icmpv6'."
  }

  validation {
    condition = alltrue([
      for rule in values(var.runner_egress_rules) :
      (rule.cidr_block != null) ||
      (rule.ipv6_cidr_block != null) ||
      (rule.prefix_list_id != null) ||
      (rule.security_group != null)
    ])
    error_message = "At least one destination must be specified."
  }
}

variable "runner_role" {
  description = <<-EOT
        additional_tags = Map of tags that will be added to the role created. Useful for tag based authorization.
        allow_iam_service_linked_role_creation = Boolean used to control attaching the policy to the Runner to create service linked roles.
        assume_role_policy_json = The assume role policy for the Runner.
        create_role_profile = Whether to create the IAM role/profile for the Runner. If you provide your own role, make sure that it has the required permissions.
        policy_arns = List of policy ARNs to be added to the instance profile of the Runner.
        role_profile_name = IAM role/profile name for the Runner. If unspecified then `$${var.iam_object_prefix}-instance` is used.
    EOT
  type = object({
    additional_tags                        = optional(map(string))
    allow_iam_service_linked_role_creation = optional(bool, true)
    assume_role_policy_json                = optional(string, "")
    create_role_profile                    = optional(bool, true)
    policy_arns                            = optional(list(string), [])
    role_profile_name                      = optional(string)
  })
  default = {}
}

variable "runner_metadata_options" {
  description = "Enable the Runner instance metadata service. IMDSv2 is enabled by default."
  type = object({
    http_endpoint               = string
    http_tokens                 = string
    http_put_response_hop_limit = number
    instance_metadata_tags      = string
  })
  default = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "disabled"
  }
}

variable "runner_schedule_enable" {
  description = "Set to `true` to enable the auto scaling group schedule for the Runner."
  type        = bool
  default     = false
}


variable "runner_enable_asg_recreation" {
  description = "Enable automatic redeployment of the Runner's ASG when the Launch Configs change."
  default     = true
  type        = bool
}

variable "runner_schedule_config" {
  description = "Map containing the configuration of the ASG scale-out and scale-in for the Runner. Will only be used if `runner_schedule_enable` is set to `true`. "
  type        = map(any)
  default = {
    # Configure optional scale_out scheduled action
    scale_out_recurrence = "0 8 * * 1-5"
    scale_out_count      = 1 # Default for min_size, desired_capacity and max_size
    scale_out_time_zone  = "Etc/UTC"
    # Override using: scale_out_min_size, scale_out_desired_capacity, scale_out_max_size

    # Configure optional scale_in scheduled action
    scale_in_recurrence = "0 18 * * 1-5"
    scale_in_count      = 0 # Default for min_size, desired_capacity and max_size
    scale_in_time_zone  = "Etc/UTC"
    # Override using: scale_out_min_size, scale_out_desired_capacity, scale_out_max_size
  }
}

variable "runner_install" {
  description = <<-EOT
    amazon_ecr_credential_helper = Install amazon-ecr-credential-helper inside `userdata_pre_install` script
    docker_machine_download_url = URL to download docker machine binary. If not set, the docker machine version will be used to download the binary.
    docker_machine_version = By default docker_machine_download_url is used to set the docker machine version. This version will be ignored once `docker_machine_download_url` is set. The version number is maintained by the CKI project. Check out at https://gitlab.com/cki-project/docker-machine/-/releases
    pre_install_script = Script to run before installing the Runner
    post_install_script = Script to run after installing the Runner
    start_script = Script to run after starting the Runner
    yum_update = Update the yum packages before installing the Runner
  EOT
  type = object({
    amazon_ecr_credential_helper = optional(bool, false)
    docker_machine_download_url  = optional(string, "")
    docker_machine_version       = optional(string, "0.16.2-gitlab.19-cki.5")
    pre_install_script           = optional(string, "")
    post_install_script          = optional(string, "")
    start_script                 = optional(string, "")
    yum_update                   = optional(bool, true)
  })
  default = {}
}

variable "runner_cloudwatch" {
  description = <<-EOT
    enable = Boolean used to enable or disable the CloudWatch logging.
    log_group_name = Option to override the default name (`environment`) of the log group. Requires `enable = true`.
    retention_days = Retention for cloudwatch logs. Defaults to unlimited. Requires `enable = true`.
  EOT
  type = object({
    enable         = optional(bool, true)
    log_group_name = optional(string, null)
    retention_days = optional(number, 0)
  })
  default = {}
}

variable "runner_gitlab_registration_config" {
  description = "(deprecated, replaced by runner_gitlab.preregistered_runner_token_ssm_parameter_name) Register the Runner manually with GitLab first."
  type = object({
    registration_token = optional(string, "__GITLAB_REGISTRATION_TOKEN_FROM_SSM__") # deprecated, do not use, will be removed
    tag_list           = optional(string, "")                                       # deprecated, do not use, will be removed
    description        = optional(string, "")                                       # deprecated, do not use, will be removed
    type               = optional(string, "")                                       # deprecated, do not use, will be removed
    group_id           = optional(string, "")                                       # deprecated, do not use, will be removed
    project_id         = optional(string, "")                                       # deprecated, do not use, will be removed
    locked_to_project  = optional(string, "")                                       # deprecated, do not use, will be removed
    run_untagged       = optional(string, "")                                       # deprecated, do not use, will be removed
    maximum_timeout    = optional(string, "")                                       # deprecated, do not use, will be removed
    access_level       = optional(string, "not_protected")                          # deprecated, do not use, will be removed
  })

  default = {}
  validation {
    condition     = contains(["group", "project", "instance", ""], var.runner_gitlab_registration_config.type)
    error_message = "The executor currently supports `group`, `project` or `instance`."
  }
}

# baee238e-1921-4801-9c3f-79ae1d7b2cbc: we don't have secrets here
# kics-scan ignore-block
variable "runner_gitlab" {
  description = <<-EOT
    ca_certificate = Trusted CA certificate bundle (PEM format).
    certificate = Certificate of the GitLab instance to connect to (PEM format).
    registration_token = (deprecated, this is replaced by the `preregistered_runner_token_ssm_parameter_name`) Registration token to use to register the Runner.
    runner_version = Version of the [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner/-/releases). Make sure that it is available for your AMI. See https://packages.gitlab.com/app/runner/gitlab-runner/search?dist=amazon%2F2023&filter=rpms&page=1&q=
    url = URL of the GitLab instance to connect to.
    url_clone = URL of the GitLab instance to clone from. Use only if the agent can’t connect to the GitLab URL.
    access_token_secure_parameter_store_name = (deprecated, this is replaced by the `preregistered_runner_token_ssm_parameter_name`) The name of the SSM parameter to read the GitLab access token from. It must have the `api` scope and be pre created.
    preregistered_runner_token_ssm_parameter_name = The name of the SSM parameter to read the preregistered GitLab Runner token from.
  EOT
  type = object({
    ca_certificate                                = optional(string, "")
    certificate                                   = optional(string, "")
    registration_token                            = optional(string, "__REPLACED_BY_USER_DATA__") # deprecated, do not use, will be removed
    runner_version                                = optional(string, "16.0.3")
    url                                           = optional(string, "")
    url_clone                                     = optional(string, "")
    access_token_secure_parameter_store_name      = optional(string, "gitlab-runner-access-token") # deprecated, do not use, will be removed
    preregistered_runner_token_ssm_parameter_name = optional(string, "")
  })
}

variable "runner_gitlab_registration_token_secure_parameter_store_name" {
  description = "(deprecated, replaced by runner_gitlab.preregistered_runner_token_ssm_parameter_name) The name of the SSM parameter to read the GitLab Runner registration token from."
  type        = string
  default     = "gitlab-runner-registration-token"
}

variable "runner_gitlab_token_secure_parameter_store" {
  description = "Name of the Secure Parameter Store entry to hold the GitLab Runner token."
  type        = string
  default     = "runner-token"
}

variable "runner_sentry_secure_parameter_store_name" {
  description = "The Sentry DSN name used to store the Sentry DSN in Secure Parameter Store"
  type        = string
  default     = "sentry-dsn"
}

# TODO Group these variables in an object to reduce the number of variables
variable "runner_terminate_ec2_lifecycle_hook_name" {
  description = "Specifies a custom name for the ASG terminate lifecycle hook and related resources."
  type        = string
  default     = null
}

variable "runner_terminate_ec2_lifecycle_timeout_duration" {
  description = "Amount of time in seconds to wait for GitLab Runner to finish picked up jobs. Defaults to the `maximum_timeout` configured + `5m`. Maximum allowed is `7200` (2 hours)"
  type        = number
  default     = null
}

variable "runner_terraform_timeout_delete_asg" {
  description = "Timeout when trying to delete the Runner ASG."
  default     = "10m"
  type        = string
}

variable "runner_terminate_ec2_timeout_duration" {
  description = "Timeout in seconds for the graceful terminate worker Lambda function."
  type        = number
  default     = 90
}

variable "runner_terminate_ec2_environment_variables" {
  description = "Environment variables to set for the Lambda function. A value of `{HANDLER} is replaced with the handler value of the Lambda function."
  type        = map(string)
  default     = {}
}

variable "runner_terminate_ec2_lambda_handler" {
  description = "The handler for the terminate Lambda function."
  type        = string
  default     = null
}

variable "runner_terminate_ec2_lambda_layer_arns" {
  description = "A list of ARNs of Lambda layers to attach to the Lambda function."
  type        = list(string)
  default     = []
}

variable "runner_terminate_ec2_lambda_egress_rules" {
  description = "Map of egress rules for the Lambda function."
  type = map(object({
    from_port       = optional(number, null)
    to_port         = optional(number, null)
    protocol        = string
    description     = string
    cidr_block      = optional(string, null)
    ipv6_cidr_block = optional(string, null)
    prefix_list_id  = optional(string, null)
    security_group  = optional(string, null)
  }))
  default = {
    allow_https_ipv4 = {
      cidr_block  = "0.0.0.0/0"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Allow HTTPS egress traffic to all destinations (IPv4)"
    },
    allow_https_ipv6 = {
      ipv6_cidr_block = "::/0"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      description     = "Allow HTTPS egress traffic to all destinations (IPv6)"
    }
  }

  validation {
    condition = alltrue([
      for rule in values(var.runner_terminate_ec2_lambda_egress_rules) :
      contains(["-1", "tcp", "udp", "icmp", "icmpv6"], rule.protocol)
    ])
    error_message = "Protocol must be '-1', 'tcp', 'udp', 'icmp', or 'icmpv6'."
  }

  validation {
    condition = alltrue([
      for rule in values(var.runner_terminate_ec2_lambda_egress_rules) :
      (rule.cidr_block != null) ||
      (rule.ipv6_cidr_block != null) ||
      (rule.prefix_list_id != null) ||
      (rule.security_group != null)
    ])
    error_message = "At least one destination must be specified."
  }
}

/*
 * Runner Worker: The process created by the Runner on the host computing platform to run jobs.
 */
# false positive, use_private_key is not a secret
# kics-scan ignore-block
variable "runner_worker" {
  description = <<-EOT
    For detailed information, check https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section.

    environment_variables = List of environment variables to add to the Runner Worker (environment).
    max_jobs = Number of jobs which can be processed in parallel by the Runner Worker.
    output_limit = Sets the maximum build log size in kilobytes. Default is 4MB (output_limit).
    request_concurrency = Limit number of concurrent requests for new jobs from GitLab (default 1) (request_concurrency).
    ssm_access = Allows to connect to the Runner Worker via SSM.
    type = The Runner Worker type to use. Currently supports `docker+machine` or `docker` or `docker-autoscaler`.
    use_private_key = Use a private key to connect the Runner Manager to the Runner Workers. Ignored when fleeting is enabled (defaults to `true`).
  EOT
  type = object({
    environment_variables = optional(list(string), [])
    max_jobs              = optional(number, 0)
    output_limit          = optional(number, 4096)
    request_concurrency   = optional(number, 1)
    ssm_access            = optional(bool, false)
    type                  = optional(string, "docker+machine")
    # false positive, use_private_key is not a secret
    # kics-scan ignore-line
    use_private_key = optional(bool, false)
  })
  default = {}

  validation {
    condition     = contains(["docker+machine", "docker", "docker-autoscaler"], var.runner_worker.type)
    error_message = "The executor currently supports `docker+machine` and `docker`."
  }
}

variable "runner_worker_cache" {
  description = <<-EOT
    Configuration to control the creation of the cache bucket. By default the bucket will be created and used as shared
    cache. To use the same cache across multiple Runner Worker disable the creation of the cache and provide a policy and
    bucket name. See the public runner example for more details."

    For detailed documentation check https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnerscaches3-section.

    access_log_bucker_id = The ID of the bucket where the access logs are stored.
    access_log_bucket_prefix = The bucket prefix for the access logs.
    authentication_type = A string that declares the AuthenticationType for [runners.cache.s3]. Can either be 'iam' or 'credentials'.
    bucket = Name of the cache bucket. Requires `create = false`.
    bucket_prefix = Prefix for s3 cache bucket name. Requires `create = true`.
    create = Boolean used to enable or disable the creation of the cache bucket.
    create_aws_s3_bucket_public_access_block = Boolean used to enable or disable the creation of the public access block for the cache bucket. Useful when organizations do not allow the creation of public access blocks on individual buckets (e.g. public access is blocked on all buckets at the organization level).
    expiration_days = Number of days before cache objects expire. Requires `create = true`.
    include_account_id = Boolean used to include the account id in the cache bucket name. Requires `create = true`.
    policy = Policy to use for the cache bucket. Requires `create = false`.
    random_suffix = Boolean used to enable or disable the use of a random string suffix on the cache bucket name. Requires `create = true`.
    shared = Boolean used to enable or disable the use of the cache bucket as shared cache.
    versioning = Boolean used to enable versioning on the cache bucket. Requires `create = true`.
  EOT
  type = object({
    access_log_bucket_id                     = optional(string, null)
    access_log_bucket_prefix                 = optional(string, null)
    authentication_type                      = optional(string, "iam")
    bucket                                   = optional(string, "")
    bucket_prefix                            = optional(string, "")
    create                                   = optional(bool, true)
    create_aws_s3_bucket_public_access_block = optional(bool, true)
    expiration_days                          = optional(number, 1)
    include_account_id                       = optional(bool, true)
    policy                                   = optional(string, "")
    random_suffix                            = optional(bool, false)
    shared                                   = optional(bool, false)
    versioning                               = optional(bool, false)
  })
  default = {}
}

variable "runner_worker_gitlab_pipeline" {
  description = <<-EOT
    post_build_script = Script to execute in the pipeline just after the build, but before executing after_script.
    pre_build_script = Script to execute in the pipeline just before the build.
    pre_clone_script = Script to execute in the pipeline before cloning the Git repository. this can be used to adjust the Git client configuration first, for example.
  EOT
  type = object({
    post_build_script = optional(string, "\"\"")
    pre_build_script  = optional(string, "\"\"")
    pre_clone_script  = optional(string, "\"\"")
  })
  default = {}
}

/*
 * Docker Executor variables.
 */
variable "runner_worker_docker_volumes_tmpfs" {
  description = "Mount a tmpfs in Executor container. https://docs.gitlab.com/runner/executors/docker.html#mounting-a-directory-in-ram"
  type = list(object({
    volume  = string
    options = string
  }))
  default = []
}

variable "runner_worker_docker_services" {
  description = "Starts additional services with the Docker container. All fields must be set (examine the Dockerfile of the service image for the entrypoint - see ./examples/runner-default/main.tf)"
  type = list(object({
    name       = string
    alias      = string
    entrypoint = list(string)
    command    = list(string)
  }))
  default = []
}

variable "runner_worker_docker_services_volumes_tmpfs" {
  description = "Mount a tmpfs in gitlab service container. https://docs.gitlab.com/runner/executors/docker.html#mounting-a-directory-in-ram"
  type = list(object({
    volume  = string
    options = string
  }))
  default = []
}

variable "runner_worker_docker_add_dind_volumes" {
  description = "Add certificates and docker.sock to the volumes to support docker-in-docker (dind)"
  type        = bool
  default     = false
}

variable "runner_worker_docker_options" {
  description = <<EOT
    Options added to the [runners.docker] section of config.toml to configure the Docker container of the Runner Worker. For
    details check https://docs.gitlab.com/runner/configuration/advanced-configuration.html

    Default values if the option is not given:
      disable_cache = "false"
      image         = "docker:18.03.1-ce"
      privileged    = "true"
      pull_policy   = "always"
      shm_size      = 0
      tls_verify    = "false"
      volumes       = "/cache"
  EOT

  type = object({
    allowed_images               = optional(list(string))
    allowed_pull_policies        = optional(list(string))
    allowed_services             = optional(list(string))
    cache_dir                    = optional(string)
    cap_add                      = optional(list(string))
    cap_drop                     = optional(list(string))
    container_labels             = optional(list(string))
    cpuset_cpus                  = optional(string)
    cpu_shares                   = optional(number)
    cpus                         = optional(string)
    devices                      = optional(list(string))
    device_cgroup_rules          = optional(list(string))
    disable_cache                = optional(bool, false)
    disable_entrypoint_overwrite = optional(bool)
    dns                          = optional(list(string))
    dns_search                   = optional(list(string))
    extra_hosts                  = optional(list(string))
    gpus                         = optional(string)
    helper_image                 = optional(string)
    helper_image_flavor          = optional(string)
    host                         = optional(string)
    hostname                     = optional(string)
    image                        = optional(string, "docker:18.03.1-ce")
    isolation                    = optional(string)
    links                        = optional(list(string))
    mac_address                  = optional(string)
    memory                       = optional(string)
    memory_swap                  = optional(string)
    memory_reservation           = optional(string)
    network_mode                 = optional(string)
    oom_kill_disable             = optional(bool)
    oom_score_adjust             = optional(number)
    privileged                   = optional(bool, true)
    pull_policies                = optional(list(string), ["always"])
    runtime                      = optional(string)
    security_opt                 = optional(list(string))
    shm_size                     = optional(number, 0)
    sysctls                      = optional(list(string))
    tls_cert_path                = optional(string)
    tls_verify                   = optional(bool, false)
    user                         = optional(string)
    userns_mode                  = optional(string)
    volumes                      = optional(list(string), ["/cache"])
    volumes_from                 = optional(list(string))
    volume_driver                = optional(string)
    wait_for_services_timeout    = optional(number)
  })

  default = {
    disable_cache = "false"
    image         = "docker:18.03.1-ce"
    privileged    = "true"
    pull_policies = ["always"]
    shm_size      = 0
    tls_verify    = "false"
    volumes       = ["/cache"]
  }
}

/*
 * docker+machine Runner Worker variables. The Runner Worker is the actual machine that runs the job. Please specify the
 * `runner_worker_docker_*` variables as well as Docker is used on the docker+machine Runner Worker.
 */
variable "runner_worker_docker_machine_fleet" {
  description = <<-EOT
    enable = Activates the fleet mode on the Runner. https://gitlab.com/cki-project/docker-machine/-/blob/v0.16.2-gitlab.19-cki.2/docs/drivers/aws.md#fleet-mode
    key_pair_name = The name of the key pair used by the Runner to connect to the docker-machine Runner Workers. This variable is only supported when `enables` is set to `true`.
  EOT
  type = object({
    enable        = bool
    key_pair_name = optional(string, "fleet-key")
  })
  default = {
    enable = false
  }
}

variable "runner_worker_docker_autoscaler" {
  description = <<-EOT
    fleeting_plugin_version = The version of aws fleeting plugin.
    connector_config_user = User to connect to worker machine.
    key_pair_name = The name of the key pair used by the Runner to connect to the docker-machine Runner Workers. This variable is only supported when `enables` is set to `true`.
    capacity_per_instance = The number of jobs that can be executed concurrently by a single instance.
    max_use_count = Max job number that can run on a worker.
    update_interval = The interval to check with the fleeting plugin for instance updates.
    update_interval_when_expecting = The interval to check with the fleeting plugin for instance updates when expecting a state change.
    instance_ready_command = Executes this command on each instance provisioned by the autoscaler to ensure that it is ready for use. A failure results in the instance being removed.
  EOT
  type = object({
    fleeting_plugin_version        = optional(string, "1.0.0")
    connector_config_user          = optional(string, "ec2-user")
    key_pair_name                  = optional(string, "runner-worker-key")
    capacity_per_instance          = optional(number, 1)
    max_use_count                  = optional(number, 100)
    update_interval                = optional(string, "1m")
    update_interval_when_expecting = optional(string, "2s")
    instance_ready_command         = optional(string, "")
  })
  default = {}
}

variable "runner_worker_docker_autoscaler_instance" {
  description = <<-EOT
    ebs_optimized = Enable EBS optimization for the Runner Worker.
    http_tokens = Whether or not the metadata service requires session tokens.
    http_put_response_hop_limit = The desired HTTP PUT response hop limit for instance metadata requests. The larger the number, the further instance metadata requests can travel.
    monitoring = Enable detailed monitoring for the Runner Worker.
    private_address_only = Restrict Runner Worker to the use of a private IP address. If `runner_instance.use_private_address_only` is set to `true` (default),
    root_device_name = The name of the root volume for the Runner Worker.
    root_size = The size of the root volume for the Runner Worker.
    start_script = Cloud-init user data that will be passed to the Runner Worker. Should not be base64 encrypted.
    start_script_compression_algorithm = `gzip` compress the start script to mitigate the ~16 KB user data limit. Use `none` for Windows (EC2Launch does not support gzipped user data).
    volume_type = The type of volume to use for the Runner Worker. `gp2`, `gp3`, `io1` or `io2` are supported.
    volume_iops = Guaranteed IOPS for the volume. Only supported when using `gp3`, `io1` or `io2` as `volume_type`.
    volume_throughput = Throughput in MB/s for the volume. Only supported when using `gp3` as `volume_type`.
EOT

  type = object({
    ebs_optimized = optional(bool, true)
    # TODO should always be "required", right? https://aquasecurity.github.io/tfsec/v1.28.0/checks/aws/ec2/enforce-launch-config-http-token-imds/
    http_tokens                        = optional(string, "required")
    http_put_response_hop_limit        = optional(number, 2)
    monitoring                         = optional(bool, false)
    private_address_only               = optional(bool, true)
    root_device_name                   = optional(string, "/dev/sda1")
    root_size                          = optional(number, 8)
    start_script                       = optional(string, "")
    start_script_compression_algorithm = optional(string, "gzip")
    volume_type                        = optional(string, "gp2")
    volume_throughput                  = optional(number, 125)
    volume_iops                        = optional(number, 3000)
  })
  default = {}

  validation {
    condition     = contains(["gzip", "none"], var.runner_worker_docker_autoscaler_instance.start_script_compression_algorithm)
    error_message = "The start_script_compression_algorithm supports `gzip` or `none`"
  }
}

variable "runner_worker_docker_autoscaler_asg" {
  description = <<-EOT
    enabled_metrics = List of metrics to collect.
    enable_mixed_instances_policy = Make use of autoscaling-group mixed_instances_policy capacities to leverage pools and spot instances.
    health_check_grace_period = Time (in seconds) after instance comes into service before checking health.
    health_check_type = Controls how health checking is done. Values are - EC2 and ELB.
    instance_refresh_min_healthy_percentage = The amount of capacity in the Auto Scaling group that must remain healthy during an instance refresh to allow the operation to continue, as a percentage of the desired capacity of the Auto Scaling group.
    instance_refresh_triggers = Set of additional property names that will trigger an Instance Refresh. A refresh will always be triggered by a change in any of launch_configuration, launch_template, or mixed_instances_policy.
    on_demand_base_capacity = Absolute minimum amount of desired capacity that must be fulfilled by on-demand instances.
    on_demand_percentage_above_base_capacity = Percentage split between on-demand and Spot instances above the base on-demand capacity.
    spot_allocation_strategy = How to allocate capacity across the Spot pools. 'lowest-price' to optimize cost, 'capacity-optimized' to reduce interruptions.
    spot_instance_pools = Number of Spot pools per availability zone to allocate capacity. EC2 Auto Scaling selects the cheapest Spot pools and evenly allocates Spot capacity across the number of Spot pools that you specify.
    subnet_ids = The list of subnet IDs to use for the Runner Worker when the fleet mode is enabled.
    default_instance_type = Default instance type for the launch template
    types = The type of instance to use for the Runner Worker. In case of fleet mode, multiple instance types are supported.
    upgrade_strategy = Auto deploy new instances when launch template changes. Can be either 'bluegreen', 'rolling' or 'off'.
    instance_requirements = Override the instance type in the Launch Template with instance types that satisfy the requirements.
  EOT
  type = object({
    enabled_metrics                          = optional(list(string), [])
    enable_mixed_instances_policy            = optional(bool, false)
    health_check_grace_period                = optional(number, 300)
    health_check_type                        = optional(string, "EC2")
    instance_refresh_min_healthy_percentage  = optional(number, 90)
    instance_refresh_triggers                = optional(list(string), [])
    on_demand_base_capacity                  = optional(number, 0)
    on_demand_percentage_above_base_capacity = optional(number, 100)
    spot_allocation_strategy                 = optional(string, "lowest-price")
    spot_instance_pools                      = optional(number, 2)
    subnet_ids                               = optional(list(string), [])
    default_instance_type                    = optional(string, "m5.large")
    types                                    = optional(list(string), [])
    upgrade_strategy                         = optional(string, "rolling")
    instance_requirements = optional(list(object({
      allowed_instance_types = optional(list(string), [])
      cpu_manufacturers      = optional(list(string), [])
      instance_generations   = optional(list(string), [])
      burstable_performance  = optional(string)
      memory_mib = optional(object({
        min = optional(number, null)
      max = optional(number, null) }), {})
      vcpu_count = optional(object({
        min = optional(number, null)
      max = optional(number, null) }), {})
    })), [])
  })
  default = {}

  validation {
    condition     = length(var.runner_worker_docker_autoscaler_asg.types) == 0 || length(var.runner_worker_docker_autoscaler_asg.instance_requirements) == 0
    error_message = "AWS does not allow setting both 'types' and 'instance_requirements' at the same time. Set only one."
  }
}

variable "runner_worker_docker_machine_role" {
  description = <<-EOT
    additional_tags = Map of tags that will be added to the Runner Worker.
    assume_role_policy_json = Assume role policy for the Runner Worker.
    policy_arns = List of ARNs of IAM policies to attach to the Runner Workers.
    profile_name    = Name of the IAM profile to attach to the Runner Workers.
  EOT
  type = object({
    additional_tags         = optional(map(string), {})
    assume_role_policy_json = optional(string, "")
    policy_arns             = optional(list(string), [])
    profile_name            = optional(string, "")
  })
  default = {}
}

variable "runner_worker_docker_autoscaler_role" {
  description = <<-EOT
    additional_tags = Map of tags that will be added to the Runner Worker.
    assume_role_policy_json = Assume role policy for the Runner Worker.
    policy_arns = List of ARNs of IAM policies to attach to the Runner Workers.
    profile_name    = Name of the IAM profile to attach to the Runner Workers.
  EOT
  type = object({
    additional_tags         = optional(map(string), {})
    assume_role_policy_json = optional(string, "")
    policy_arns             = optional(list(string), [])
    profile_name            = optional(string, "")
  })
  default = {}
}

variable "runner_worker_ingress_rules" {
  description = "Map of ingress rules for the Runner workers"
  type = map(object({
    from_port       = optional(number, null)
    to_port         = optional(number, null)
    protocol        = string
    description     = string
    cidr_block      = optional(string, null)
    ipv6_cidr_block = optional(string, null)
    prefix_list_id  = optional(string, null)
    security_group  = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for rule in values(var.runner_worker_ingress_rules) :
      contains(["-1", "tcp", "udp", "icmp", "icmpv6"], rule.protocol)
    ])
    error_message = "Protocol must be '-1', 'tcp', 'udp', 'icmp', or 'icmpv6'."
  }

  validation {
    condition = alltrue([
      for rule in values(var.runner_worker_ingress_rules) :
      (rule.cidr_block != null) ||
      (rule.ipv6_cidr_block != null) ||
      (rule.prefix_list_id != null) ||
      (rule.security_group != null)
    ])
    error_message = "At least one destination must be specified."
  }
}

variable "runner_worker_egress_rules" {
  description = "Map of egress rules for the Runner workers"
  type = map(object({
    from_port       = optional(number, null)
    to_port         = optional(number, null)
    protocol        = string
    description     = string
    cidr_block      = optional(string, null)
    ipv6_cidr_block = optional(string, null)
    prefix_list_id  = optional(string, null)
    security_group  = optional(string, null)
  }))
  default = {
    allow_https_ipv4 = {
      cidr_block  = "0.0.0.0/0"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Allow HTTPS egress traffic to all destinations (IPv4)"
    },
    allow_https_ipv6 = {
      ipv6_cidr_block = "::/0"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      description     = "Allow HTTPS egress traffic to all destinations (IPv6)"
    },
    allow_http_ipv4 = {
      cidr_block  = "0.0.0.0/0"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Allow HTTP egress traffic to all destinations (IPv4)"
    },
    allow_http_ipv6 = {
      ipv6_cidr_block = "::/0"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      description     = "Allow HTTP egress traffic to all destinations (IPv6)"
    },
    allow_ssh_ipv4 = {
      cidr_block  = "0.0.0.0/0"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Allow SSH egress traffic to all destinations (IPv4)"
    },
    allow_ssh_ipv6 = {
      ipv6_cidr_block = "::/0"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      description     = "Allow SSH egress traffic to all destinations (IPv6)"
    }
  }

  validation {
    condition = alltrue([
      for rule in values(var.runner_worker_egress_rules) :
      contains(["-1", "tcp", "udp", "icmp", "icmpv6"], rule.protocol)
    ])
    error_message = "Protocol must be '-1', 'tcp', 'udp', 'icmp', or 'icmpv6'."
  }

  validation {
    condition = alltrue([
      for rule in values(var.runner_worker_egress_rules) :
      (rule.cidr_block != null) ||
      (rule.ipv6_cidr_block != null) ||
      (rule.prefix_list_id != null) ||
      (rule.security_group != null)
    ])
    error_message = "At least one destination must be specified."
  }
}

variable "runner_worker_docker_machine_security_group_description" {
  description = "A description for the Runner Worker security group"
  type        = string
  default     = "A security group containing Runner Worker instances"
}

variable "runner_worker_docker_machine_ami_filter" {
  description = "List of maps used to create the AMI filter for the Runner Worker (docker-machine)."
  type        = map(list(string))

  default = {
    name = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

variable "runner_worker_docker_machine_ami_owners" {
  description = "The list of owners used to select the AMI of the Runner Worker (docker-machine)."
  type        = list(string)

  # Canonical
  default = ["099720109477"]
}

variable "runner_worker_docker_machine_ami_id" {
  description = "The ID of the AMI to use for the Runner Worker (docker-machine)."
  type        = string
  default     = ""
}

variable "runner_worker_docker_autoscaler_ami_filter" {
  description = "List of maps used to create the AMI filter for the Runner Worker (autoscaler)."
  type        = map(list(string))

  default = {
    name = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

variable "runner_worker_docker_autoscaler_ami_owners" {
  description = "The list of owners used to select the AMI of the Runner Worker (autoscaler)."
  type        = list(string)

  # Canonical
  default = ["099720109477"]
}

variable "runner_worker_docker_autoscaler_ami_id" {
  description = "The ID of the AMI to use for the Runner Worker (autoscaler)."
  type        = string
  default     = ""
}

variable "runner_worker_docker_machine_instance" {
  description = <<-EOT
    For detailed documentation check https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnersmachine-section

    docker_registry_mirror_url = The URL of the Docker registry mirror to use for the Runner Worker.
    destroy_after_max_builds = Destroy the instance after the maximum number of builds has been reached.
    ebs_optimized = Enable EBS optimization for the Runner Worker.
    idle_count = Number of idle Runner Worker instances (not working for the Docker Runner Worker) (IdleCount).
    idle_time = Idle time of the Runner Worker before they are destroyed (not working for the Docker Runner Worker) (IdleTime).
    max_growth_rate = The maximum number of machines that can be added to the runner in parallel.
    monitoring = Enable detailed monitoring for the Runner Worker.
    name_prefix = Set the name prefix and override the `Name` tag for the Runner Worker.
    private_address_only = Restrict Runner Worker to the use of a private IP address. If `runner_instance.use_private_address_only` is set to `true` (default), `runner_worker_docker_machine_instance.private_address_only` will also apply for the Runner.
    root_device_name = The name of the root volume for the Runner Worker.
    root_size = The size of the root volume for the Runner Worker.
    start_script = Cloud-init user data that will be passed to the Runner Worker. Should not be base64 encrypted.
    subnet_ids = The list of subnet IDs to use for the Runner Worker when the fleet mode is enabled.
    types = The type of instance to use for the Runner Worker. In case of fleet mode, multiple instance types are supported.
    volume_type = The type of volume to use for the Runner Worker. `gp2`, `gp3`, `io1` or `io2` are supported.
    volume_throughput = Throughput in MB/s for the volume. Only supported when using `gp3` as `volume_type`.
    volume_iops = Guaranteed IOPS for the volume. Only supported when using `gp3`, `io1` or `io2` as `volume_type`. Works for fleeting only. See `runner_worker_docker_machine_fleet`.
  EOT
  type = object({
    destroy_after_max_builds   = optional(number, 0)
    docker_registry_mirror_url = optional(string, "")
    ebs_optimized              = optional(bool, true)
    idle_count                 = optional(number, 0)
    idle_time                  = optional(number, 600)
    max_growth_rate            = optional(number, 0)
    monitoring                 = optional(bool, false)
    name_prefix                = optional(string, "")
    private_address_only       = optional(bool, true)
    root_device_name           = optional(string, "/dev/sda1")
    root_size                  = optional(number, 8)
    start_script               = optional(string, "")
    subnet_ids                 = optional(list(string), [])
    types                      = optional(list(string), ["m5.large"])
    volume_type                = optional(string, "gp2")
    volume_throughput          = optional(number, 125)
    volume_iops                = optional(number, 3000)
  })
  default = {
  }

  validation {
    condition     = length(var.runner_worker_docker_machine_instance.name_prefix) <= 28
    error_message = "Maximum length for docker+machine executor name is 28 characters!"
  }

  validation {
    condition     = var.runner_worker_docker_machine_instance.name_prefix == "" || can(regex("^[a-zA-Z0-9\\.-]+$", var.runner_worker_docker_machine_instance.name_prefix))
    error_message = "Valid characters for the docker+machine executor name are: [a-zA-Z0-9\\.-]."
  }

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.runner_worker_docker_machine_instance.volume_type)
    error_message = "Supported volume types: gp2, gp3, io1 and io2"
  }
}

variable "runner_worker_docker_machine_instance_spot" {
  description = <<-EOT
    enable = Enable spot instances for the Runner Worker.
    max_price = The maximum price willing to pay. By default the price is limited by the current on demand price for the instance type chosen.
  EOT
  type = object({
    enable    = optional(bool, true)
    max_price = optional(string, "on-demand-price")
  })
  default = {}
}

variable "runner_worker_docker_machine_ec2_options" {
  description = "List of additional options for the docker+machine config. Each element of this list must be a key=value pair. E.g. '[\"amazonec2-zone=a\"]'"
  type        = list(string)
  default     = []
}

variable "runner_worker_docker_machine_ec2_metadata_options" {
  description = "Enable the Runner Worker metadata service. Requires you use CKI maintained docker machines."
  type = object({
    http_tokens                 = string
    http_put_response_hop_limit = number
  })
  default = {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }
}

variable "runner_worker_docker_machine_autoscaling_options" {
  description = "Set autoscaling parameters based on periods, see https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnersmachine-section"
  type = list(object({
    periods           = list(string)
    idle_count        = optional(number)
    idle_scale_factor = optional(number)
    idle_count_min    = optional(number)
    idle_time         = optional(number)
    timezone          = optional(string, "UTC")
  }))
  default = []
}

variable "runner_worker_docker_autoscaler_autoscaling_options" {
  description = "Set autoscaling parameters based on periods, see https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnersautoscalerpolicy-sections"
  type = list(object({
    periods            = list(string)
    timezone           = optional(string, "UTC")
    idle_count         = optional(number)
    idle_time          = optional(string)
    scale_factor       = optional(number)
    scale_factor_limit = optional(number, 0)
    preemptive_mode    = optional(bool)
  }))
  default = []
}

variable "debug" {
  description = <<-EOT
    trace_runner_user_data: Enable bash trace for the user data script on the Agent. Be aware this could log sensitive data such as you GitLab runner token.
    write_runner_config_to_file: When enabled, outputs the rendered config.toml file in the root module. Note that enabling this can
                                 potentially expose sensitive information.
    write_runner_user_data_to_file: When enabled, outputs the rendered userdata.sh file in the root module. Note that enabling this
                                    can potentially expose sensitive information.
  EOT
  type = object({
    trace_runner_user_data         = optional(bool, false)
    write_runner_config_to_file    = optional(bool, false)
    write_runner_user_data_to_file = optional(bool, false)
  })
  default = {}
}
