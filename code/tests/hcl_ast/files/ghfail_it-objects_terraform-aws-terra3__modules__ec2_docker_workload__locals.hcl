# -----------------------------------------------
# EC2 Docker Workload Module - Locals
# -----------------------------------------------

locals {
  # Security groups: use provided or create default
  security_groups = length(var.security_group_ids) > 0 ? var.security_group_ids : [aws_security_group.default[0].id]

  # Docker volume mount string for user data
  # Converts ebs_volumes list to Docker -v bind mount arguments
  docker_volume_mounts = join(" ", [
    for vol in var.ebs_volumes :
    "-v /mnt/${trimprefix(vol.device_name, "/dev/")}:${vol.mount_path}"
  ])

  # Environment variables for Docker run command
  # Converts map to Docker -e arguments
  docker_env_vars = join(" ", [
    for key, value in var.environment_variables :
    "-e ${key}=\"${replace(value, "\"", "\\\\")}\"" # Escape quotes in values
  ])

  # Secrets configuration for user data script
  # Converts map of env_var_name -> ssm_arn to JSON for passing to script
  docker_secrets_json = jsonencode(var.map_secrets)

  # Separate secrets by type for IAM policies
  # For Secrets Manager, strip JSON key suffix (e.g., :json_key::) to get base secret ARN
  # Use distinct() to avoid duplicate ARNs in the policy
  ssm_secret_arns = distinct([for arn in var.map_secrets : arn if can(regex("arn:aws:ssm:", arn))])
  sm_secret_arns = distinct([for arn in var.map_secrets :
    can(regex("arn:aws:secretsmanager:", arn)) ?
    regex("^(arn:aws:secretsmanager:[^:]+:[^:]+:secret:[^:]+)(?::[^:]+::)?$", arn)[0] :
    ""
    if can(regex("arn:aws:secretsmanager:", arn))
  ])

  # Port mappings for Docker run command
  docker_port_args = join(" ", [
    for pm in var.port_mappings :
    "-p ${pm.hostPort}:${pm.containerPort}/${pm.protocol}"
  ])

  # Common tags for all resources
  common_tags = merge(
    var.tags,
    {
      Name             = "${var.solution_name}-${var.instance_name}"
      ManagedBy        = "Terraform"
      Solution         = var.solution_name
      WorkloadInstance = var.instance_name
    }
  )

  # Parameter paths for SSM discovery
  ssm_param_prefix = "/${var.solution_name}/ec2_docker_workload/${var.instance_name}"

  # Internal DNS configuration (zone managed by base module, read from SSM)
  internal_dns_zone_id       = try(data.aws_ssm_parameter.internal_dns_zone_id[0].value, "")
  internal_dns_zone_name     = try(data.aws_ssm_parameter.internal_dns_zone_name[0].value, "")
  internal_dns_workload_name = var.internal_dns_workload_name != "" ? var.internal_dns_workload_name : var.instance_name
  internal_dns_record_name   = var.enable_internal_dns ? "${local.internal_dns_workload_name}.${local.internal_dns_zone_name}" : ""

  # Persistent volumes (those that should NOT be deleted on termination)
  persistent_volumes = [for vol in var.ebs_volumes : vol if vol.delete_on_termination == false]

  # Get AZ for volume creation
  # Volumes must be created in the same AZ as the instance
  # This is required to prevent EBS volume replacement on re-apply
  volume_az = var.ebs_volume_availability_zone

  # Extract ECR repository name from docker_image_uri if it's an ECR image
  # ECR format: 123456789.dkr.ecr.us-east-1.amazonaws.com/repo-name:tag
  # Public format: postgres:15 or nginx:latest
  is_ecr_image  = can(regex("dkr\\.ecr\\.", var.docker_image_uri))
  ecr_repo_name = local.is_ecr_image ? split("/", split(":", var.docker_image_uri)[0])[1] : ""

  # -----------------------------------------------
  # ALB Configuration
  # -----------------------------------------------

  # Determine if we should use HTTPS listener (port 443)
  # by checking if the ALB has a valid HTTPS listener ARN
  use_https_listener = (
    var.enable_load_balancer &&
    !var.internal_service &&
    try(data.aws_ssm_parameter.alb_listener_443_arn[0].value != "-", false)
  )

  # Select the appropriate listener ARN based on HTTPS availability
  alb_listener_arn = (
    local.use_https_listener ?
    try(data.aws_ssm_parameter.alb_listener_443_arn[0].value, "") :
    try(data.aws_ssm_parameter.alb_listener_80_arn[0].value, "")
  )

  # Get the host port from the first port_mapping (for health checks and target group)
  service_port = var.enable_load_balancer && length(var.port_mappings) > 0 ? var.port_mappings[0].hostPort : 0

}
