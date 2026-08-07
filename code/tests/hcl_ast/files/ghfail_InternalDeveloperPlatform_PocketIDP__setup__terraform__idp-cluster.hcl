# Configure k8s cluster by exposing the locally running Kubernetes Cluster to the Humanitec Orchestrator
# using the Humanitec Agent

resource "tls_private_key" "agent_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  agent_id = "${local.prefix}agent"
}

resource "humanitec_agent" "agent" {
  id          = local.agent_id
  description = "5min-idp"
  public_keys = [{
    key = tls_private_key.agent_private_key.public_key_pem
  }]
}

resource "helm_release" "humanitec_agent" {
  name             = "humanitec-agent"
  namespace        = "humanitec-agent"
  create_namespace = true

  repository = "oci://ghcr.io/humanitec/charts"
  chart      = "humanitec-agent"

  set {
    name  = "humanitec.org"
    value = var.humanitec_org
  }

  set {
    name  = "humanitec.privateKey"
    value = tls_private_key.agent_private_key.private_key_pem
  }

  depends_on = [
    humanitec_agent.agent
  ]
}

resource "humanitec_resource_definition" "agent" {
  id   = local.agent_id
  name = local.agent_id
  type = "agent"

  driver_type = "humanitec/agent"
  driver_inputs = {
    values_string = jsonencode({
      id = local.agent_id
    })
  }

  depends_on = [
    helm_release.humanitec_agent
  ]
}
resource "humanitec_resource_definition_criteria" "agent_local" {
  resource_definition_id = humanitec_resource_definition.agent.id
  res_id                 = "agent"
  env_type               = local.env_type

  force_delete = true
  depends_on   = [humanitec_environment_type.local]
}

locals {
  parsed_kubeconfig = yamldecode(file(var.kubeconfig))
}

resource "humanitec_resource_definition" "cluster_local" {
  id          = "${local.prefix}k8s-cluster"
  name        = "${local.prefix}k8s-cluster"
  type        = "k8s-cluster"
  driver_type = "humanitec/k8s-cluster"

  driver_inputs = {
    values_string = jsonencode({
      loadbalancer = "0.0.0.0" # ensure dns records are created pointing to localhost
      cluster_data = local.parsed_kubeconfig["clusters"][0]["cluster"]
    })
    secrets_string = jsonencode({
      agent_url   = "$${resources['agent#agent'].outputs.url}"
      credentials = local.parsed_kubeconfig["users"][0]["user"]
    })
  }
}

resource "humanitec_resource_definition_criteria" "cluster_local" {
  resource_definition_id = humanitec_resource_definition.cluster_local.id
  env_type               = local.env_type

  force_delete = true

  depends_on = [
    humanitec_resource_definition_criteria.agent_local, humanitec_environment_type.local
  ]
}
