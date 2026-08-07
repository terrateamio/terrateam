# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY TILLER INTO A NEW NAMESPACE
# These templates show an example of how to deploy Tiller following security best practices. This entails:
# - Creating a Namespace and ServiceAccount for Tiller
# - Creating a separate Namespace for the resources to go into
# - Using kubergrunt to deploy Tiller with TLS management
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_version = ">= 0.12"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CONFIGURE OUR KUBERNETES CONNECTIONS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

provider "kubernetes" {
  config_context = var.kubectl_config_context_name
  config_path    = var.kubectl_config_path
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE THE NAMESPACE WITH RBAC ROLES AND SERVICE ACCOUNT
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

module "tiller_namespace" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::https://github.com/gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-namespace?ref=v0.3.0"
  source = "./modules/k8s-namespace"

  name = var.tiller_namespace
}

module "resource_namespace" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::https://github.com/gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-namespace?ref=v0.3.0"
  source = "./modules/k8s-namespace"

  name = var.resource_namespace
}

module "tiller_service_account" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::https://github.com/gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-service-account?ref=v0.3.0"
  source = "./modules/k8s-service-account"

  name           = var.service_account_name
  namespace      = module.tiller_namespace.name
  num_rbac_roles = 2

  rbac_roles = [
    {
      name      = module.tiller_namespace.rbac_tiller_metadata_access_role
      namespace = module.tiller_namespace.name
    },
    {
      name      = module.resource_namespace.rbac_tiller_resource_access_role
      namespace = module.resource_namespace.name
    },
  ]

  labels = {
    app = "tiller"
  }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY TILLER
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

module "tiller" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::https://github.com/gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-tiller?ref=v0.3.0"
  source = "./modules/k8s-tiller"

  tiller_service_account_name              = module.tiller_service_account.name
  tiller_service_account_token_secret_name = module.tiller_service_account.token_secret_name
  namespace                                = module.tiller_namespace.name
  tiller_image_version                     = var.tiller_version

  tiller_tls_gen_method   = "provider"
  tiller_tls_subject      = var.tls_subject
  private_key_algorithm   = var.private_key_algorithm
  private_key_ecdsa_curve = var.private_key_ecdsa_curve
  private_key_rsa_bits    = var.private_key_rsa_bits
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# GENERATE CLIENT TLS CERTIFICATES FOR USE WITH HELM CLIENT
# These certs will be stored in Kubernetes Secrets, in a format compatible with `kubergrunt helm configure`
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

module "helm_client_tls_certs" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::https://github.com/gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-helm-client-tls-certs?ref=v0.3.1"
  source = "./modules/k8s-helm-client-tls-certs"

  ca_tls_certificate_key_pair_secret_namespace = module.tiller.tiller_ca_tls_certificate_key_pair_secret_namespace
  ca_tls_certificate_key_pair_secret_name      = module.tiller.tiller_ca_tls_certificate_key_pair_secret_name

  tls_subject                               = var.client_tls_subject
  tls_certificate_key_pair_secret_namespace = module.tiller_namespace.name

  # Kubergrunt expects client cert secrets to be stored under this name format

  tls_certificate_key_pair_secret_name = "tiller-client-${md5(local.rbac_entity_id)}-certs"
  tls_certificate_key_pair_secret_labels = {
    "gruntwork.io/tiller-namespace"        = module.tiller_namespace.name
    "gruntwork.io/tiller-credentials"      = "true"
    "gruntwork.io/tiller-credentials-type" = "client"
  }
}

locals {
  rbac_entity_id = var.grant_helm_client_rbac_user != "" ? var.grant_helm_client_rbac_user : var.grant_helm_client_rbac_group != "" ? var.grant_helm_client_rbac_group : var.grant_helm_client_rbac_service_account != "" ? var.grant_helm_client_rbac_service_account : ""
}