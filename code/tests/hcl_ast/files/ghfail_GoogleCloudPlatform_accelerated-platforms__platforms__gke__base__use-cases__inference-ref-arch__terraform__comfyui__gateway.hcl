# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

locals {
  comfyui_endpoint            = local.comfyui_endpoints_hostname
  comfyui_port                = 8188
  comfyui_service_name        = "${var.comfyui_app_name}-${var.comfyui_accelerator_type}"
  gateway_manifests_directory = "${local.manifests_directory}/gateway"
  hostname_suffix             = "endpoints.${data.google_project.cluster.project_id}.cloud.goog"
  iap_domain                  = var.comfyui_iap_domain != null ? var.comfyui_iap_domain : split("@", trimspace(data.google_client_openid_userinfo.identity.email))[1]
  iap_oath_brand              = "projects/${data.google_project.comfyui_iap_oath_branding.number}/brands/${data.google_project.comfyui_iap_oath_branding.number}"
  kubeconfig_directory        = "${path.module}/../../../../kubernetes/kubeconfig"
  kubeconfig_file             = "${local.kubeconfig_directory}/${local.kubeconfig_file_name}"
  manifests_directory         = "${local.namespace_directory}/${var.comfyui_kubernetes_namespace}"
  manifests_directory_root    = "${path.module}/../../../../kubernetes/manifests"
  namespace_directory         = "${local.manifests_directory_root}/namespace"
  serviceaccount              = "${local.unique_identifier_prefix}-${local.comfyui_default_name}"

  comfyui_backend_service_regex = ".*${var.comfyui_kubernetes_namespace}-${local.comfyui_service_name}-${local.comfyui_port}-.*"
}

data "google_client_config" "default" {}

data "google_client_openid_userinfo" "identity" {}

###############################################################################
# Create Namespace
###############################################################################

data "local_file" "kubeconfig" {
  filename = local.kubeconfig_file
}

resource "local_file" "comfyui_namespace_manifest" {
  content = templatefile(
    "${path.module}/templates/namespace/namespace-comfyui.tftpl.yaml",
    {
      app_name  = var.comfyui_app_name
      namespace = var.comfyui_kubernetes_namespace
    }
  )
  filename = "${local.namespace_directory}/namespace-${var.comfyui_kubernetes_namespace}.yaml"
}

module "kubectl_apply_comfyui_namespace_manifest" {
  depends_on = [
    local_file.comfyui_namespace_manifest,
  ]

  source = "../../../../modules/kubectl_apply"

  kubeconfig_file             = data.local_file.kubeconfig.filename
  manifest                    = local_file.comfyui_namespace_manifest.filename
  manifest_includes_namespace = true
}

###############################################################################
# Setup service account and network policies in the namespace
###############################################################################

resource "local_file" "comfyui_serviceaccount" {
  content = templatefile(
    "${path.module}/templates/namespace/serviceaccount.tftpl.yaml",
    {
      name      = local.serviceaccount
      namespace = var.comfyui_kubernetes_namespace
    }
  )
  filename = "${local.manifests_directory}/serviceaccount-${local.serviceaccount}.yaml"
}

resource "local_file" "comfyui_network_policy" {
  content = templatefile(
    "${path.module}/templates/namespace/network-policy.tftpl.yaml",
    {
      name      = var.comfyui_kubernetes_namespace
      namespace = var.comfyui_kubernetes_namespace
    }
  )
  filename = "${local.manifests_directory}/network-policy.yaml"
}

module "kubectl_apply_namespace_setup" {
  depends_on = [
    local_file.comfyui_network_policy,
    local_file.comfyui_serviceaccount,
    module.kubectl_apply_comfyui_namespace_manifest,
  ]

  source = "../../../../modules/kubectl_apply"

  kubeconfig_file             = data.local_file.kubeconfig.filename
  manifest                    = local.manifests_directory
  manifest_includes_namespace = true
}

###############################################################################
# GATEWAY
###############################################################################
resource "google_project_service" "certificatemanager_googleapis_com" {
  disable_dependent_services = false
  disable_on_destroy         = false
  project                    = data.google_project.cluster.project_id
  service                    = "certificatemanager.googleapis.com"
}

resource "google_compute_managed_ssl_certificate" "external_gateway" {
  depends_on = [
    google_project_service.certificatemanager_googleapis_com,
  ]

  name    = local.comfyui_endpoints_ssl_certificate_name
  project = data.google_project.cluster.project_id

  managed {
    domains = [
      local.comfyui_endpoint,
    ]
  }
}

resource "google_compute_global_address" "external_gateway_https" {
  name    = local.comfyui_gateway_address_name
  project = data.google_project.cluster.project_id
}

resource "local_file" "gateway_external_https_yaml" {
  depends_on = [
    google_compute_global_address.external_gateway_https
  ]

  content = templatefile(
    "${path.module}/templates/gateway/gateway-external-https.tftpl.yaml",
    {
      address_name         = google_compute_global_address.external_gateway_https.name
      gateway_name         = local.comfyui_gateway_name
      namespace            = var.comfyui_kubernetes_namespace
      ssl_certificate_name = google_compute_managed_ssl_certificate.external_gateway.name
    }
  )
  filename = "${local.gateway_manifests_directory}/gateway-external-https.yaml"
}

# ENDPOINTS
###############################################################################
resource "terraform_data" "comfyui_https_endpoint_undelete" {
  provisioner "local-exec" {
    command     = "gcloud endpoints services undelete ${local.comfyui_endpoint} --project=${data.google_project.cluster.project_id} --quiet >/dev/null 2>&1 || exit 0"
    interpreter = ["bash", "-c"]
    working_dir = path.module
  }
}

resource "google_endpoints_service" "comfyui_https" {
  depends_on = [
    terraform_data.comfyui_https_endpoint_undelete,
  ]

  openapi_config = templatefile(
    "${path.module}/templates/openapi/endpoint.tftpl.yaml",
    {
      endpoint   = local.comfyui_endpoint
      ip_address = google_compute_global_address.external_gateway_https.address
    }
  )
  project      = data.google_project.cluster.project_id
  service_name = local.comfyui_endpoint
}

# ROUTES
###############################################################################
resource "local_file" "route_comfyui_https_yaml" {
  content = templatefile(
    "${path.module}/templates/gateway/http-route-service.tftpl.yaml",
    {
      gateway_name    = local.comfyui_gateway_name
      hostname        = local.comfyui_endpoint
      http_route_name = "comfyui-https"
      namespace       = var.comfyui_kubernetes_namespace
      service_name    = local.comfyui_service_name
      service_port    = local.comfyui_port
    }
  )
  filename = "${local.gateway_manifests_directory}/route-comfyui-https.yaml"
}

###############################################################################
# IAP Policy
###############################################################################
resource "local_file" "policy_iap_comfyui_yaml" {
  depends_on = [
    module.kubectl_apply_namespace_setup,
  ]

  content = templatefile(
    "${path.module}/templates/gateway/gcp-backend-policy-iap-service.tftpl.yaml",
    {
      policy_name  = "comfyui"
      service_name = local.comfyui_service_name
      namespace    = var.comfyui_kubernetes_namespace
    }
  )
  filename = "${local.gateway_manifests_directory}/policy-iap-comfyui.yaml"
}

###############################################################################
# Apply gateway resources
###############################################################################
module "kubectl_apply_gateway_res" {
  depends_on = [
    google_endpoints_service.comfyui_https,
    local_file.gateway_external_https_yaml,
    local_file.policy_iap_comfyui_yaml,
    local_file.route_comfyui_https_yaml,
    module.kubectl_apply_namespace_setup,
  ]

  source = "../../../../modules/kubectl_apply"

  kubeconfig_file             = data.local_file.kubeconfig.filename
  manifest                    = local.gateway_manifests_directory
  manifest_includes_namespace = true
}

###############################################################################
# IAP Permissions
###############################################################################
module "kubectl_wait_for_gateway" {
  depends_on = [
    module.kubectl_apply_gateway_res,
    module.kubectl_apply_workload_manifest,
  ]

  source = "../../../../modules/kubectl_wait"

  for             = "jsonpath={.status.conditions[?(@.type==\"networking.gke.io/GatewayHealthy\")].status}=True"
  kubeconfig_file = data.local_file.kubeconfig.filename
  namespace       = var.comfyui_kubernetes_namespace
  resource        = "gateway/${local.comfyui_gateway_name}"
  timeout         = "300s"
  wait_for_create = true
}

data "kubernetes_resources" "gateway" {
  depends_on = [
    module.kubectl_wait_for_gateway
  ]

  api_version    = "gateway.networking.k8s.io/v1"
  kind           = "Gateway"
  field_selector = "metadata.name==${local.comfyui_gateway_name}"
  namespace      = var.comfyui_kubernetes_namespace
}

resource "google_iap_web_backend_service_iam_member" "service_account_iap_https_resource_accessor" {
  member  = "domain:${local.iap_domain}"
  project = local.cluster_project_id
  role    = "roles/iap.httpsResourceAccessor"
  web_backend_service = basename(
    one(
      [
        for backend in split(", ", data.kubernetes_resources.gateway.objects[0].metadata.annotations["networking.gke.io/backend-services"]) : backend
        if can(regex(local.comfyui_backend_service_regex, backend))
      ]
    )
  )
}
