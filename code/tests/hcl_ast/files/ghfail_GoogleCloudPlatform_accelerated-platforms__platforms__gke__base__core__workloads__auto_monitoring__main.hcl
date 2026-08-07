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
  kubeconfig_directory = "${path.module}/../../../kubernetes/kubeconfig"
  kubeconfig_file      = "${local.kubeconfig_directory}/${local.kubeconfig_file_name}"

  kubernetes_namespace = var.cluster_autopilot_enabled ? "gke-gmp-system" : "gmp-system"
}

data "local_file" "kubeconfig" {
  filename = local.kubeconfig_file
}

module "kubectl_wait" {
  for_each = toset(var.cluster_auto_monitoring_config_scope == "ALL" && var.cluster_autopilot_enabled == false ? ["managed-prometheus-operator"] : [])

  source = "../../../modules/kubectl_wait"

  for             = "condition=ready"
  kubeconfig_file = data.local_file.kubeconfig.filename
  namespace       = local.kubernetes_namespace
  resource        = "pod"
  selector        = "app=managed-prometheus-operator"
  timeout         = "300s"
}
