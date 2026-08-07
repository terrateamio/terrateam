variable "subnet_ids" {
  description = "A list of subnets to place the EKS cluster and workers within."
  type        = list(any)
}

variable "vpc_id" {
  description = "VPC where the cluster and workers will be deployed."
  type        = string
}

variable "docker_storage_size" {
  default     = 100
  type        = number
  description = "EBS Volume size in Gib that the ECS Instance uses for Docker images and metadata"
}

variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap. See examples/eks_test_fixture/variables.tf for example format."
  type        = list(string)
  default     = []
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap. Consider switching to owner_roles and read_only_roles."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "owner_roles" {
  description = "List of IAM roles that should be added to the aws-auth configmap with system:masters group."
  type        = list(string)
  default     = []
}

variable "read_only_roles" {
  description = "List of IAM roles that should be added to the aws-auth configmap with read-only access."
  type        = list(string)
  default     = []
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap. See examples/eks_test_fixture/variables.tf for example format."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "cluster_name" {
  description = "Use this to set the eks cluster name directly. NOTE: if the `cluster_name` is not specified, you will not be able to use Karpenter."
  type        = string
  default     = ""
}

variable "iam_cluster_name_prefix" {
  description = "Optional prefix for the cluster IAM role name. If both `cluster_name` and `iam_cluster_name_prefix` are specified, use the value of `iam_cluster_name_prefix` as the cluster IAM role prefix; for all other cases use the `cluster_name` as a prefix."
  type        = string
  default     = null
}

variable "cluster_enabled_log_types" {
  default     = null
  description = "A list of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)"
  type        = list(any)
}

variable "cluster_version" {
  default     = "1.30"
  description = "EKS cluster version"
  type        = string
}

variable "tags" {
  type = object({
    project : string,
    service : string,
    env : string,
    owner : string,
    managedBy : string,
  })
  description = "Typically fogg's var.tags"
}

// https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html
// https://github.com/awslabs/amazon-eks-ami/releases
variable "ami_release_version" {
  description = "AMI release version"
  default     = ""
  type        = string
}

variable "fargate_profiles" {
  description = "Map of Fargate Profile definitions to create"
  type        = any
  default     = {}
}

# This variable is now deprecated. By default, this module will use Karpenter to autoscale the cluster.
variable "node_groups" {
  type = map(object({
    size          = optional(number, 1), # statically sized
    capacity_type = optional(string, "SPOT"),
    // architecture is optional, but if you do provide it you need to provide
    // both the ami_type and the instance_types so that you don't accidently mix and
    // match the wrong AMI and CPU architectures. defaults to a valid ARM architecture.
    architecture = optional(object({
      ami_type       = string
      instance_types = list(string)
      }),
      {
        ami_type       = "AL2023_ARM_64_STANDARD"
        instance_types = ["t4g.large"]
    }),
    taints = optional(map(object({
      key    = string
      value  = string
      effect = string
    })), {}),
    labels               = optional(map(string), {}),
    force_update_version = optional(bool, true),
  }))
  default = {
    # default_arm = {
    #   size          = 1
    #   capacity_type = "SPOT"
    #   architecture = {
    #     ami_type       = "AL2023_ARM_64_STANDARD"
    #     instance_types = ["t4g.large"]
    #   }
    # },
    # default_x86 = {
    #   size          = 1
    #   capacity_type = "SPOT"
    #   architecture = {
    #     ami_type       = "AL2023_x86_64_STANDARD"
    #     instance_types = ["t3a.large"]
    #   }
    # }
  }
  description = "Map of node groups for this cluster. Make sure the instance_type correctly matches the architecture."
  validation {
    condition = alltrue([for k, v in var.node_groups :
      v.capacity_type == "SPOT" ||
      v.capacity_type == "ON_DEMAND"
    ])
    error_message = "capacity_type must be either SPOT or ON_DEMAND."
  }
  validation {
    condition = alltrue([for k, v in var.node_groups :
      v.architecture.ami_type == "AL2023_ARM_64_STANDARD" ||
      v.architecture.ami_type == "AL2023_ARM_64_NVIDIA" ||
      v.architecture.ami_type == "AL2023_x86_64_STANDARD" ||
      v.architecture.ami_type == "AL2023_x86_64_NEURON" ||
      v.architecture.ami_type == "AL2023_x86_64_NVIDIA" ||
      v.architecture.ami_type == "BOTTLEROCKET_x86_64" ||
      v.architecture.ami_type == "BOTTLEROCKET_ARM_64" ||
      v.architecture.ami_type == "BOTTLEROCKET_x86_64_NVIDIA" ||
      v.architecture.ami_type == "BOTTLEROCKET_ARM_64_NVIDIA"
    ])
    error_message = "AMI architecture must be supported (AL2 is end of life)."
  }
  validation {
    condition     = alltrue([for k, v in var.node_groups : length(v.architecture.instance_types) > 0])
    error_message = "architecture instance_types must be a non-empty list."
  }
}

variable "authorized_github_repos" {
  description = "Map of Github owner and repo identifiers that will be used to create a role for Github Actions to assume. Maps might look like {owner = [\"reponame1\", \"reponame2\"]}"
  type        = map(list(string))
  default     = {}
}

variable "authorized_aws_accounts" {
  type        = map(string)
  description = "The map of authorized AWS accounts to assume the created role."
  default     = {}
}

//https://aws.amazon.com/blogs/containers/leveraging-amazon-eks-managed-node-group-with-placement-group-for-low-latency-critical-applications/
variable "placement_group_strategy" {
  description = "Placement group strategy for the EKS cluster (`cluster`, `partition` or `spread` are supported). Defaults to `partition` strategy."
  type        = string
  default     = "partition"

  validation {
    condition     = var.placement_group_strategy == "cluster" || var.placement_group_strategy == "partition" || var.placement_group_strategy == "spread"
    error_message = "placement_group_strategy must be either cluster or partition or spread."
  }
}

variable "addons" {
  description = "Map of addon definitions to create"
  type = object({
    enable_guardduty                    = optional(bool, false)
    enable_aws_load_balancer_controller = optional(bool, true)
    enable_metrics_server               = optional(bool, true)
    enable_cert_manager                 = optional(bool, true)
    enable_aws_for_fluentbit            = optional(bool, false)
    enable_external_dns                 = optional(bool, true)
    enable_karpenter                    = optional(bool, true)
    enable_default_karpenter_nodepool   = optional(bool, true)
    enable_default_karpenter_nodeclass  = optional(bool, true)
    enable_aws_efs_csi_driver           = optional(bool, true)
    enable_argocd                       = optional(bool, false)
    enable_aws_cloudwatch_metrics       = optional(bool, false)
    enable_external_secrets             = optional(bool, false)
    enable_fargate_fluentbit            = optional(bool, false)
    enable_ingress_nginx                = optional(bool, false)
    enable_kube_prometheus_stack        = optional(bool, false)
    enable_crossplane                   = optional(bool, false) // Deprecated, use crossplane module instead
    fluentbit_exclude_paths             = optional(list(string), [])
    aws_for_fluentbit_cw_log_group = optional(any, {
      create          = true
      retention       = 7
      use_name_prefix = false
    })
    external_secrets_config = optional(any, {
      service_account_name = "external-secrets-sa",
      namespace            = "external-secrets",
      wait                 = true
    })
    external_secrets_secrets_manager_arns = optional(list(string), ["arn:aws:secretsmanager:*:*:secret:/argus/*"])
    argocd_config                         = optional(any, {})
    argocd_child_config = optional(object({
      enabled = optional(bool, true)
      root_argo_aws_account_id_to_role = optional(map(string), {
        "533267185808" = "argo_root_core_platform_infra_prod_eks",
        "471112759938" = "argo_root_core_platform_infra_dev_eks",
      })
    }), {})
    karpenter_config = optional(any, {
      chart_version = "1.6.1"
    })
    karpenter_nodepool_spec = optional(any, null)
    enable_karpenter_capacity_reservation = optional(bool, false)
    karpenter_capacity_reservation = optional(object({
      ec2_node_class_name = optional(string, "odcr")
      selector_terms      = list(any)
    }), null)
    external_dns_config = optional(object({
      chart_version = optional(string, "1.18.0")
      image_tag     = optional(string, "v0.19.0")
      policy        = optional(string, "upsert-only")
      sources       = optional(list(string), ["service", "ingress"])
    }), {})
    cert_manager_route53_hosted_zone_arns = optional(list(string), ["arn:aws:route53:::hostedzone/*"])
    cert_manager_config                   = optional(any, {})
  })
  default = {}
}

variable "addons_data" {
  description = "Map of data addons to config to create"
  type = object({
    enable_kubecost = optional(bool, false)

    enable_jupyterhub = optional(bool, false)
    jupyterhub_helm_config = optional(object({
      callback_url : string,
      client_id : string,
      client_secret : string,
      authorize_url : string,
      token_url : string,
      allowed_groups : string,
      jupyter_single_user_sa_name : string,
      issuer : string,
      secret_name : string,
      storage_class_name : string,
      admin_groups : string,
      additional_server_image : string,
      }), {
      callback_url : "",
      client_id : "",
      client_secret : "",
      authorize_url : "",
      token_url : "",
      allowed_groups : "",
      jupyter_single_user_sa_name : "",
      issuer : "",
      secret_name : "",
      storage_class_name : "",
      admin_groups : "",
      additional_server_image : "",
    })
  })
  default = {}
}

variable "identity_provider_configurations" {
  type = map(
    object(
      {
        client_id                     = string
        groups_claim                  = optional(string, null)
        groups_prefix                 = optional(string, null)
        identity_provider_config_name = string
        issuer_url                    = string
        required_claims               = optional(map(string))
        username_claim                = optional(string, null)
        username_prefix               = optional(string, null)
      }
    )
  )
  default     = {}
  description = "Set of EKS Identity Provider Configurations for non-AWS access to the EKS cluster. The key and the name should only have letters/numbers, hyphens, and underscores. Direct reference from this link: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_identity_provider_config"
}

variable "enable_audit_s3_ingest" {
  type        = bool
  description = "Whether you want to send the EKS Audit to an s3 bucket in czi-logs."
  default     = false
}

variable "logs_bucket_name" {
  type        = string
  description = "name of the bucket that will hold the cloudwatch logs"
  default     = "czi-eks-cloudwatch-logs"
}

variable "aws_org_id" {
  type        = string
  description = "The org ID this cluster will be in. May be used in assume roles and pathfinding."
  default     = "o-56v5gp5fcu"
}
