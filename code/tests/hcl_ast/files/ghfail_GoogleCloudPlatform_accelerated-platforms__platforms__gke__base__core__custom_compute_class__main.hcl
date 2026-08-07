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
  kubeconfig_directory = "${path.module}/../../kubernetes/kubeconfig"
  kubeconfig_file      = "${local.kubeconfig_directory}/${local.kubeconfig_file_name}"

  manifests_directory                 = "${local.manifests_directory_root}/cluster/ccc"
  manifests_directory_root            = "${path.module}/../../kubernetes/manifests"
  template_manifests_directory        = "${path.module}/manifests/ccc"
  template_manifests_source_directory = "${path.module}/templates/manifests"

  template_manifests_source_directory_contents_hash = sha512(join("", [for f in fileset(local.template_manifests_source_directory, "**") : filesha512("${local.template_manifests_source_directory}/${f}")]))
}

data "local_file" "kubeconfig" {
  filename = local.kubeconfig_file
}

resource "terraform_data" "manifests" {
  input = {
    manifests_directory                 = local.manifests_directory
    template_manifests_directory        = local.template_manifests_directory
    template_manifests_source_directory = local.template_manifests_source_directory
  }

  provisioner "local-exec" {
    command     = <<EOT
mkdir -p "${self.input.template_manifests_directory}" && \
mkdir -p "${self.input.manifests_directory}" && \
cp -r "${self.input.template_manifests_source_directory}"/* "${self.input.template_manifests_directory}/" && \
cp -r "${self.input.template_manifests_directory}"/* "${self.input.manifests_directory}/"
EOT
    interpreter = ["bash", "-c"]
    working_dir = path.module
  }

  triggers_replace = {
    manifests_directory          = local.manifests_directory
    template_manifests_directory = local.template_manifests_directory

    # Trigger whenever the contents of source directories change.
    # Don't depend on destination directory content because it might change between plan and apply.
    template_manifests_source_directory_contents_hash = local.template_manifests_source_directory_contents_hash,
  }
}

module "kubectl_apply_manifests" {
  depends_on = [
    terraform_data.manifests,
  ]

  source = "../../modules/kubectl_apply"

  apply_once                  = false
  apply_server_side           = true
  kubeconfig_file             = data.local_file.kubeconfig.filename
  manifest                    = local.template_manifests_directory
  manifest_includes_namespace = true
  recursive                   = true
  source_content_hash         = local.template_manifests_source_directory_contents_hash
  use_kustomize               = false
}

module "kubectl_wait" {
  depends_on = [
    module.kubectl_apply_manifests,
  ]

  source = "../../modules/kubectl_wait"

  filename        = local.manifests_directory
  for             = "jsonpath={.status.conditions[?(@.type==\"Health\")].reason}=Health"
  kubeconfig_file = data.local_file.kubeconfig.filename
  timeout         = "180s"
}

resource "terraform_data" "check" {
  depends_on = [
    module.kubectl_wait
  ]

  for_each = toset(var.cluster_check_custom_compute_classes_healthy ? ["enabled"] : [])

  provisioner "local-exec" {
    command = <<EOT
kubectl get computeclass -o jsonpath='{range .items[*]}{.metadata.name}{": "}{.status.conditions[*].message}{"\n"}{end}' && 
exit $(kubectl get ComputeClass -o jsonpath='{range .items[*]}{.metadata.name}{": "}{.status.conditions[*].message}{"\n"}{end}' | grep -c 'not healthy')
EOT
    environment = {
      KUBECONFIG = data.local_file.kubeconfig.filename
    }
    interpreter = ["bash", "-c"]
    working_dir = path.module
  }
}
