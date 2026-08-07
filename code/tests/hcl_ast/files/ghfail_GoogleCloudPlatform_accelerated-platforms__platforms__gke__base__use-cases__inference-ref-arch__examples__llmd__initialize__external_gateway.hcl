# Copyright 2024 Google LLC
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

#################################################################################
# This file create resources required for external access of the frontend(gradio)
# abstracting llmd inference scheduler
#################################################################################
resource "google_compute_managed_ssl_certificate" "external_gateway" {
  depends_on = [
    google_project_service.cluster["certificatemanager.googleapis.com"],
  ]

  name    = local.llmd_endpoints_ssl_certificate_name
  project = data.google_project.cluster.project_id

  managed {
    domains = [
      local.llmd_endpoint,
    ]
  }
}

resource "google_compute_global_address" "external_gateway_https" {
  name    = local.llmd_gateway_address_name
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
      gateway_name         = local.llmd_gateway_name_external
      namespace            = local.ira_online_gpu_kubernetes_namespace_name
      ssl_certificate_name = google_compute_managed_ssl_certificate.external_gateway.name
    }
  )
  filename = "${local.external_gateway_manifests_directory}/gateway-external-https.yaml"
}

# ENDPOINTS
resource "terraform_data" "llmd_https_endpoint_undelete" {
  provisioner "local-exec" {
    command     = "gcloud endpoints services undelete ${local.llmd_endpoint} --project=${data.google_project.cluster.project_id} --quiet >/dev/null 2>&1 || exit 0"
    interpreter = ["bash", "-c"]
    working_dir = path.module
  }
}

resource "google_endpoints_service" "llmd_https" {
  depends_on = [
    terraform_data.llmd_https_endpoint_undelete,
  ]

  openapi_config = templatefile(
    "${path.module}/templates/openapi/endpoint.tftpl.yaml",
    {
      endpoint   = local.llmd_endpoint
      ip_address = google_compute_global_address.external_gateway_https.address
    }
  )
  project      = data.google_project.cluster.project_id
  service_name = local.llmd_endpoint
}

#HTTP route
resource "local_file" "external_route" {
  content = templatefile(
    "${path.module}/templates/gateway/httproute-external.tftpl.yaml",
    {
      httproute_name       = local.llmd_httproute_name_external
      kubernetes_namespace = local.ira_online_gpu_kubernetes_namespace_name
      gateway_name         = local.llmd_gateway_name_external
      hostname             = local.llmd_endpoint
      service_name         = local.gradio_service_name
      service_port         = local.gradio_service_port
    }
  )
  file_permission = "0644"
  filename        = "${local.external_gateway_manifests_directory}/httproute-external.yaml"
}

# IAP Policy
resource "local_file" "policy_iap_llmd_yaml" {
  content = templatefile(
    "${path.module}/templates/gateway/gcp-backend-policy-iap-service.tftpl.yaml",
    {
      policy_name  = "gradio-policy"
      service_name = local.gradio_service_name
      namespace    = local.ira_online_gpu_kubernetes_namespace_name
    }
  )
  filename = "${local.external_gateway_manifests_directory}/policy-iap-llmd.yaml"
}

# Apply external gateway manifests
module "kubectl_apply_ext_gateway_res" {
  depends_on = [
    google_endpoints_service.llmd_https,
    local_file.gateway_external_https_yaml,
    local_file.policy_iap_llmd_yaml,
    local_file.external_route,
  ]

  source = "../../../../../modules/kubectl_apply"

  kubeconfig_file             = data.local_file.kubeconfig.filename
  manifest                    = local.external_gateway_manifests_directory
  manifest_includes_namespace = true
}

# IAP Permissions
module "kubectl_wait_for_gateway" {
  depends_on = [
    module.kubectl_apply_ext_gateway_res,
    module.kubectl_apply_gradio,
  ]

  source = "../../../../../modules/kubectl_wait"

  for             = "jsonpath={.status.conditions[?(@.type==\"networking.gke.io/GatewayHealthy\")].status}=True"
  kubeconfig_file = data.local_file.kubeconfig.filename
  namespace       = local.ira_online_gpu_kubernetes_namespace_name
  resource        = "gateway/${local.llmd_gateway_name_external}"
  timeout         = "300s"
  wait_for_create = true
}

data "kubernetes_resources" "gateway" {
  depends_on = [
    module.kubectl_wait_for_gateway
  ]

  api_version    = "gateway.networking.k8s.io/v1"
  kind           = "Gateway"
  field_selector = "metadata.name==${local.llmd_gateway_name_external}"
  namespace      = local.ira_online_gpu_kubernetes_namespace_name
}

resource "google_iap_web_backend_service_iam_member" "service_account_iap_https_resource_accessor" {
  member  = "domain:${local.iap_domain}"
  project = local.cluster_project_id
  role    = "roles/iap.httpsResourceAccessor"
  web_backend_service = basename(
    one(
      [
        for backend in split(", ", data.kubernetes_resources.gateway.objects[0].metadata.annotations["networking.gke.io/backend-services"]) : backend
        if can(regex(local.gradio_backend_service_regex, backend))
      ]
    )
  )
}
