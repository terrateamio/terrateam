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
  gateway_manifests_directory = "${local.manifests_directory}/namespace/${local.mft_kubernetes_namespace}/gateway"
  gateway_name                = "external-https"
}

resource "google_compute_managed_ssl_certificate" "external_gateway" {
  depends_on = [
    google_project_service.certificatemanager_googleapis_com,
  ]

  name    = "${local.unique_identifier_prefix}-${local.mft_kubernetes_namespace}-external-gateway"
  project = data.google_project.cluster.project_id

  managed {
    domains = [for endpoint in local.mft_endpoints : endpoint.host]
  }
}

resource "google_compute_global_address" "external_gateway_https" {
  name    = "${local.unique_identifier_prefix}-${local.mft_kubernetes_namespace}-external-gateway-https"
  project = data.google_project.cluster.project_id
}

resource "local_file" "gateway_external_https_yaml" {
  content = templatefile(
    "${path.module}/templates/gateway/gateway-external-https.tftpl.yaml",
    {
      address_name         = google_compute_global_address.external_gateway_https.name,
      gateway_name         = local.gateway_name,
      ssl_certificate_name = google_compute_managed_ssl_certificate.external_gateway.name
    }
  )
  filename = "${local.gateway_manifests_directory}/gateway-external-https.yaml"
}

resource "local_file" "route" {
  for_each = local.mft_endpoints

  content = templatefile(
    "${path.module}/templates/gateway/http-route-service.tftpl.yaml",
    {
      gateway_name    = local.gateway_name,
      http_route_name = "${each.key}-https",
      hostname        = each.value.host
      service_name    = each.value.service_name
      service_port    = each.value.port
    }
  )
  filename = "${local.gateway_manifests_directory}/route-${each.key}-https.yaml"
}

resource "local_file" "gcp_backend_policy" {
  for_each = local.mft_endpoints

  content = templatefile(
    "${path.module}/templates/gateway/gcp-backend-policy-iap-service.tftpl.yaml",
    {
      policy_name  = each.key
      service_name = each.value.service_name
    }
  )
  filename = "${local.gateway_manifests_directory}/gcp-backend-policy-${each.key}.yaml"
}

# Apply Kubernetes manifests
###############################################################################
module "kubectl_apply_gateway_manifest" {
  depends_on = [
    module.kubectl_apply_namespace_manifest,
  ]
  source = "../../../../modules/kubectl_apply"

  kubeconfig_file = data.local_file.kubeconfig.filename
  manifest        = local_file.gateway_external_https_yaml.filename
  namespace       = local.mft_kubernetes_namespace
}

module "kubectl_apply_route_manifest" {
  depends_on = [
    module.kubectl_apply_namespace_manifest,
  ]
  source = "../../../../modules/kubectl_apply"

  for_each = local_file.gcp_backend_policy

  kubeconfig_file = data.local_file.kubeconfig.filename
  manifest        = local_file.route[each.key].filename
  namespace       = local.mft_kubernetes_namespace
}

module "kubectl_apply_gcp_backend_policy_manifest" {
  depends_on = [
    module.kubectl_apply_namespace_manifest,
  ]
  source = "../../../../modules/kubectl_apply"

  for_each = local_file.route

  kubeconfig_file = data.local_file.kubeconfig.filename
  manifest        = local_file.gcp_backend_policy[each.key].filename
  namespace       = local.mft_kubernetes_namespace
}

module "kubectl_wait_for_gateway" {
  depends_on = [
    module.kubectl_apply_gateway_manifest,
  ]

  source = "../../../../modules/kubectl_wait"

  for             = "jsonpath={.status.conditions[?(@.type==\"networking.gke.io/GatewayHealthy\")].status}=True"
  kubeconfig_file = data.local_file.kubeconfig.filename
  namespace       = local.mft_kubernetes_namespace
  resource        = "gateway/${local.gateway_name}"
  timeout         = "300s"
  wait_for_create = true
}
