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
  gateway_subnetwork_name = "${local.unique_identifier_prefix}-gateway"
  proxy_subnetwork_name   = "${local.unique_identifier_prefix}-proxy"

  gateway_manifests_directory = "${local.namespace_manifests_directory}/gateway-${local.workflow_api_default_name}"

  hostname_suffix = "endpoints.${data.google_project.cluster.project_id}.cloud.goog"

  iap_oath_brand = "projects/${data.google_project.comfyui_iap_oath_branding.number}/brands/${data.google_project.comfyui_iap_oath_branding.number}"

  workflow_api_service_name   = local.workflow_api_default_name
  workflow_api_service_port   = 8080
  workflow_api_serviceaccount = "${local.unique_identifier_prefix}-${local.workflow_api_default_name}"

  workflow_api_backend_service_regex = ".*${var.comfyui_kubernetes_namespace}-${local.workflow_api_default_name}-8080-.*"
}

data "google_client_config" "default" {}

data "google_client_openid_userinfo" "identity" {}

###############################################################################
# Setup service account for workflow-api in the namespace
###############################################################################

resource "local_file" "workflow_api_serviceaccount" {
  content = templatefile(
    "${path.module}/templates/serviceaccount.tftpl.yaml",
    {
      name      = local.workflow_api_serviceaccount
      namespace = var.comfyui_kubernetes_namespace
    }
  )
  filename = "${local.namespace_manifests_directory}/serviceaccount-${local.workflow_api_serviceaccount}.yaml"
}

module "kubectl_apply_serviceaccount" {
  depends_on = [
    local_file.workflow_api_serviceaccount,
  ]

  source = "../../../../modules/kubectl_apply"

  kubeconfig_file             = data.local_file.kubeconfig.filename
  manifest                    = local_file.workflow_api_serviceaccount.filename
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

resource "google_compute_global_address" "external_gateway_https" {
  name    = local.workflow_api_gateway_address_name
  project = data.google_project.cluster.project_id
}

resource "google_compute_managed_ssl_certificate" "workflow_api" {
  depends_on = [
    google_project_service.certificatemanager_googleapis_com,
  ]

  name    = local.workflow_api_endpoints_ssl_certificate_name
  project = data.google_project.cluster.project_id

  managed {
    domains = [
      local.workflow_api_endpoints_hostname,
    ]
  }
}

resource "local_file" "external_gateway_https_yaml" {
  content = templatefile(
    "${path.module}/templates/gateway-external-https.tftpl.yaml",
    {
      address_name         = google_compute_global_address.external_gateway_https.name
      gateway_name         = local.workflow_api_gateway_name
      namespace            = var.comfyui_kubernetes_namespace
      ssl_certificate_name = google_compute_managed_ssl_certificate.workflow_api.name
    }
  )
  filename = "${local.gateway_manifests_directory}/${local.workflow_api_gateway_name}.yaml"
}

resource "local_file" "health_check_policy_yaml" {
  content = templatefile(
    "${path.module}/templates/health-check-policy.tftpl.yaml",
    {
      policy_name  = local.workflow_api_default_name
      service_name = local.workflow_api_service_name
      namespace    = var.comfyui_kubernetes_namespace
    }
  )
  filename = "${local.gateway_manifests_directory}/health-check-policy-${local.workflow_api_default_name}.yaml"
}

resource "local_file" "route_workflow_api_https_yaml" {
  content = templatefile(
    "${path.module}/templates/http-route-service.tftpl.yaml",
    {
      gateway_name    = local.workflow_api_gateway_name
      hostname        = local.workflow_api_endpoints_hostname
      http_route_name = "${local.workflow_api_default_name}-https"
      namespace       = var.comfyui_kubernetes_namespace
      service_name    = local.workflow_api_service_name
      service_port    = local.workflow_api_service_port
    }
  )
  filename = "${local.gateway_manifests_directory}/route-${local.workflow_api_default_name}-https.yaml"
}

###############################################################################
# IAP
###############################################################################
resource "local_file" "policy_iap_workflow_api_yaml" {
  content = templatefile(
    "${path.module}/templates/gcp-backend-policy-iap-service.tftpl.yaml",
    {
      policy_name  = local.workflow_api_default_name
      service_name = local.workflow_api_service_name
      namespace    = var.comfyui_kubernetes_namespace
    }
  )
  filename = "${local.gateway_manifests_directory}/gcp-backend-policy-${local.workflow_api_default_name}.yaml"
}

###############################################################################
# ENDPOINTS
###############################################################################
resource "terraform_data" "workflow_api_https_endpoint_undelete" {
  provisioner "local-exec" {
    command     = "gcloud endpoints services undelete ${local.workflow_api_endpoints_hostname} --project=${data.google_project.cluster.project_id} --quiet >/dev/null 2>&1 || exit 0"
    interpreter = ["bash", "-c"]
    working_dir = path.module
  }
}

resource "google_endpoints_service" "workflow_api_https" {
  depends_on = [
    terraform_data.workflow_api_https_endpoint_undelete,
    google_compute_global_address.external_gateway_https,
  ]

  openapi_config = templatefile(
    "${path.module}/templates/endpoint.tftpl.yaml",
    {
      endpoint   = local.workflow_api_endpoints_hostname
      ip_address = google_compute_global_address.external_gateway_https.address
    }
  )
  project      = data.google_project.cluster.project_id
  service_name = local.workflow_api_endpoints_hostname
}

###############################################################################
# Apply gateway resources
###############################################################################
module "kubectl_apply_gateway_res" {
  depends_on = [
    google_endpoints_service.workflow_api_https,
    local_file.external_gateway_https_yaml,
    local_file.policy_iap_workflow_api_yaml,
    local_file.route_workflow_api_https_yaml,
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
  resource        = "gateway/${local.workflow_api_gateway_name}"
  timeout         = "300s"
  wait_for_create = true
}

data "kubernetes_resources" "gateway" {
  depends_on = [
    module.kubectl_wait_for_gateway
  ]

  api_version    = "gateway.networking.k8s.io/v1"
  kind           = "Gateway"
  field_selector = "metadata.name==${local.workflow_api_gateway_name}"
  namespace      = var.comfyui_kubernetes_namespace
}

resource "google_iap_web_backend_service_iam_member" "service_account_iap_https_resource_accessor" {
  member  = google_service_account.workflow_api_user.member
  role    = "roles/iap.httpsResourceAccessor"
  project = local.cluster_project_id
  web_backend_service = basename(
    one(
      [
        for backend in split(", ", data.kubernetes_resources.gateway.objects[0].metadata.annotations["networking.gke.io/backend-services"]) : backend
        if can(regex(local.workflow_api_backend_service_regex, backend))
      ]
    )
  )
}
