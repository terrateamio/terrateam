module "vpc" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.5.0"

  component = var.vpc_component_name

  context = module.cluster.context
}

module "vpc_ingress" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.5.0"

  for_each = {
    for i, account in var.allow_ingress_from_vpc_accounts :
    try(account.tenant, module.this.tenant) != null ?
    format("%s-%s", account.tenant, account.stage) : account.stage => account
  }

  component   = each.value.vpc
  tenant      = try(each.value.tenant, module.this.tenant)
  environment = try(each.value.environment, module.this.environment)
  stage       = try(each.value.stage, module.this.stage)

  context = module.cluster.context
}

module "eks" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.5.0"

  for_each  = local.eks_security_group_enabled ? var.eks_component_names : toset([])
  component = each.value

  context = module.cluster.context
}


module "dns_gbl_delegated" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.5.0"

  component   = "dns-delegated"
  environment = var.dns_gbl_delegated_environment_name

  context = module.cluster.context
}
