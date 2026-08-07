variable "name" {
  description = "Name prefix for the deployment (e.g. 'soft-mt')"
  type        = string
  validation {
    condition     = length(var.name) > 0
    error_message = "Name must not be empty."
  }
}

variable "host_kubeconfig_path" {
  description = "Path to the host cluster kubeconfig"
  type        = string
  default     = "~/.kube/config"
}

variable "host_kube_context" {
  description = "Kubeconfig context to use for the host cluster. If empty, uses the current context."
  type        = string
  default     = ""
}

variable "kubeconfig_output_dir" {
  description = "Directory where vCluster kubeconfig files will be written"
  type        = string
  default     = "."
}

variable "skip_kubeconfig" {
  description = "Skip writing vCluster kubeconfig files to disk"
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# vCluster Platform
# ---------------------------------------------------------------------------

variable "platform_url" {
  description = "URL of the vCluster Platform (e.g. https://platform.example.com)"
  type        = string
}

variable "platform_access_key" {
  description = "Access key for the vCluster Platform API"
  type        = string
  sensitive   = true
}

variable "platform_project_name" {
  description = "vCluster Platform project to deploy into"
  type        = string
  default     = "default"
}

variable "platform_insecure" {
  description = "Skip TLS verification for the vCluster Platform API"
  type        = bool
  default     = false
}

variable "vcluster_chart_version" {
  description = "vCluster Helm chart version"
  type        = string
  default     = "0.31.0"
}

# ---------------------------------------------------------------------------
# NVIDIA Run:ai Control Plane (external)
# ---------------------------------------------------------------------------

variable "runai_cp_url" {
  description = "URL of the external NVIDIA Run:ai control plane (e.g. https://runai.example.com). Used for REST API calls from terraform."
  type        = string
  validation {
    condition     = can(regex("^https?://", var.runai_cp_url))
    error_message = "Control plane URL must start with http:// or https://."
  }
}

variable "runai_admin_email" {
  description = "Admin email for the NVIDIA Run:ai control plane API"
  type        = string
  default     = "admin@run.ai"
  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.runai_admin_email))
    error_message = "Must be a valid email address."
  }
}

variable "runai_admin_password" {
  description = "Admin password for the NVIDIA Run:ai control plane API"
  type        = string
  sensitive   = true
}

variable "runai_chart_version" {
  description = "NVIDIA Run:ai Helm chart version (used for agent)"
  type        = string
  default     = "2.24.18"
}

variable "runai_agent_chart_repo" {
  description = "Helm chart repository for the NVIDIA Run:ai cluster agent"
  type        = string
  default     = "https://runai.jfrog.io/artifactory/api/helm/run-ai-charts"
}

variable "runai_registry_credentials" {
  description = "Base64-encoded Docker config JSON for the NVIDIA Run:ai registry"
  type        = string
  sensitive   = true
}

variable "runai_cp_ca_cert" {
  description = "Base64-encoded PEM CA certificate for the NVIDIA Run:ai control plane (required when using self-signed TLS)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "runai_cp_insecure" {
  description = "Skip TLS verification for the NVIDIA Run:ai control plane API"
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Agents
# ---------------------------------------------------------------------------

variable "agents" {
  description = "List of cluster agents to register and deploy as vClusters"
  type = list(object({
    name                          = string
    domain                        = string
    workload_domain               = optional(string, "")
    node_selector_label_value     = optional(string, "")
    inference_domain              = optional(string, "")
    inference_service_annotations = optional(map(string), {})
    ingress_service_annotations   = optional(map(string), {})
    cluster_uid                   = optional(string, "")
    # Note: client_secret cannot be marked sensitive inside an object type.
    # Plan output may display this value. Use an encrypted remote backend.
    client_secret = optional(string, "")
  }))
  default = []

  validation {
    condition = alltrue([
      for a in var.agents :
      (a.cluster_uid == "" && a.client_secret == "") ||
      (a.cluster_uid != "" && a.client_secret != "")
    ])
    error_message = "Each agent must provide both cluster_uid and client_secret, or neither."
  }
}

# ---------------------------------------------------------------------------
# Node Selection
# ---------------------------------------------------------------------------

variable "node_selector_label_key" {
  description = "Label key used to assign dedicated host nodes to agent vClusters (e.g. 'tenant')"
  type        = string
  default     = "tenant"
}

# ---------------------------------------------------------------------------
# High Availability
# ---------------------------------------------------------------------------

variable "high_availability" {
  description = "Enable HA for agent vClusters (multiple replicas + embedded etcd)"
  type        = bool
  default     = false
}

variable "ha_replicas" {
  description = "Number of vCluster control plane replicas when HA is enabled"
  type        = number
  default     = 3
}

# ---------------------------------------------------------------------------
# Helm Chart Versions (shared)
# ---------------------------------------------------------------------------

variable "raw_chart_version" {
  description = "Bedag raw Helm chart version (used to deploy Knative Serving CR)"
  type        = string
  default     = "2.0.2"
}

# ---------------------------------------------------------------------------
# GPU Operator
# ---------------------------------------------------------------------------

variable "deploy_gpu_operator" {
  description = "Deploy NVIDIA GPU Operator inside agent vClusters"
  type        = bool
  default     = true
}

variable "gpu_operator_version" {
  description = "NVIDIA GPU Operator Helm chart version"
  type        = string
  default     = "v25.10.1"
}

variable "gpu_operator_driver_enabled" {
  description = "Enable NVIDIA driver installation via GPU Operator"
  type        = bool
  default     = false
}

variable "gpu_operator_device_plugin_enabled" {
  description = "Enable the GPU Operator's device plugin. Set to false when the host already provides one (e.g. GKE)"
  type        = bool
  default     = true
}

variable "gpu_operator_driver_install_dir" {
  description = "Host path where NVIDIA drivers are installed. On GKE with Google-managed drivers use /home/kubernetes/bin/nvidia"
  type        = string
  default     = "/run/nvidia/driver"
}

# ---------------------------------------------------------------------------
# Prometheus Operator
# ---------------------------------------------------------------------------

variable "deploy_prometheus_operator" {
  description = "Deploy kube-prometheus-stack CRDs inside agent vClusters"
  type        = bool
  default     = true
}

variable "kube_prometheus_stack_version" {
  description = "kube-prometheus-stack Helm chart version"
  type        = string
  default     = "72.6.2"
}

# ---------------------------------------------------------------------------
# Inference (Knative)
# ---------------------------------------------------------------------------

variable "enable_inference" {
  description = "Enable Knative Serving for inference workloads in agent vClusters"
  type        = bool
  default     = true
}

variable "knative_operator_version" {
  description = "Knative Operator Helm chart version"
  type        = string
  default     = "1.18.0"
}

variable "knative_serving_version" {
  description = "Knative Serving version installed by the operator"
  type        = string
  default     = "1.16.3"
}
