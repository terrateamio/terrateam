locals {
  vpcs = var.tgw_config.vpcs
  eks  = var.tgw_config.eks

  own_account_vpc_key = "${var.owning_account}-${var.own_vpc_component_name}"
  own_vpc             = local.vpcs[local.own_account_vpc_key].outputs
  is_network_hub      = (module.this.stage == var.network_account_stage_name) ? true : false

  # Create a list of all VPC component keys. Key includes stack + component
  #
  # Example var.connections
  #  connections:
  #    - account:
  #        tenant: core
  #        stage: network
  #      vpc_component_names:
  #        - vpc-dev
  #    - account:
  #        tenant: core
  #        stage: auto
  #    - account:
  #        tenant: plat
  #        stage: dev
  #    - account:
  #        tenant: plat
  #        stage: dev
  #        environment: usw2
  connected_vpc_component_keys = flatten(
    [
      for c in var.connections :
      [
        # Default value for c.vpc_component_names is ["vpc"]
        for vpc in c.vpc_component_names :
        # This component key needs to match the key created by tgw/hub
        # See components/terraform/tgw/hub/remote-state.tf
        length(c.account.environment) > 0 ?
        (length(c.account.tenant) > 0 ?
          "${c.account.tenant}-${c.account.environment}-${c.account.stage}-${vpc}" :
        "${c.account.environment}-${c.account.stage}-${vpc}")
        :
        (length(c.account.tenant) > 0 ?
          "${c.account.tenant}-${module.this.environment}-${c.account.stage}-${vpc}" :
        "${module.this.environment}-${c.account.stage}-${vpc}")
      ]
    ]
  )

  # Create a list of all EKS component keys.
  # Follows same pattern as vpc_component_names
  connected_eks_component_keys = flatten(
    [
      for c in var.connections :
      [
        for eks in c.eks_component_names :
        length(c.account.environment) > 0 ?
        (length(c.account.tenant) > 0 ?
          "${c.account.tenant}-${c.account.environment}-${c.account.stage}-${eks}" :
        "${c.account.environment}-${c.account.stage}-${eks}")
        :
        (length(c.account.tenant) > 0 ?
          "${c.account.tenant}-${module.this.environment}-${c.account.stage}-${eks}" :
        "${module.this.environment}-${c.account.stage}-${eks}")
      ]
    ]
  )

  # Define a list of all VPCs allowed to access this account's VPC.
  # Filter the tgw_config output from tgw/hub for VPCs and pull the CIDR of a VPC if
  # (1) this is not the primary VPC that we are connecting to and (2) this VPC key is given as a connection
  allowed_vpcs = {
    for vpc_key, vpc_remote_state in local.vpcs :
    vpc_key => {
      cidr         = vpc_remote_state.outputs.vpc_cidr
      cross_region = (vpc_remote_state.outputs.environment != module.this.environment)
      environment  = vpc_remote_state.outputs.environment
    } if vpc_key != local.own_account_vpc_key && contains(local.connected_vpc_component_keys, vpc_key)
  }

  # For each EKS cluster in this account, map the EKS SG to the CIDR for each connected cluster
  allowed_eks = merge([
    for own_eks_component in var.own_eks_component_names :
    {
      for eks_key, eks_remote_state in local.eks :
      eks_key => {
        # SG of each EKS component in this account
        sg_id = local.eks["${var.owning_account}-${own_eks_component}"].outputs.eks_cluster_managed_security_group_id
        # CIDR of the remote EKS cluster
        cidr = eks_remote_state.outputs.vpc_cidr
      } if contains(local.connected_eks_component_keys, eks_key)
    }
  ]...)

  cross_region_vpcs = flatten([
    for vpc_key, vpc in local.allowed_vpcs : [
      {
        vpc_key     = vpc_key
        cidr        = vpc.cidr
        environment = vpc.environment
      }
    ] if vpc.cross_region
  ])

  cross_region_vpc_route_table_ids = flatten([
    for vpc_key, vpc in local.allowed_vpcs : [
      for route_table_key, route_table_id in local.own_vpc.private_route_table_ids : [
        {
          vpc_key        = vpc_key
          rt_key         = route_table_key
          cidr           = vpc.cidr
          route_table_id = route_table_id
        }
      ]
    ] if vpc.cross_region
  ])
}

# Create a TGW attachment from this account's VPC to the TGW Hub
# This includes a merged list of all CIDRs from allowed VPCs in connected accounts
module "standard_vpc_attachment" {
  source  = "cloudposse/transit-gateway/aws"
  version = "0.11.0"

  existing_transit_gateway_id             = var.tgw_config.existing_transit_gateway_id
  existing_transit_gateway_route_table_id = var.tgw_config.existing_transit_gateway_route_table_id

  route_keys_enabled                                             = true
  create_transit_gateway                                         = false
  create_transit_gateway_route_table                             = false
  create_transit_gateway_vpc_attachment                          = true
  create_transit_gateway_route_table_association_and_propagation = false

  config = {
    (var.owning_account) = {
      vpc_id                            = local.own_vpc.vpc_id
      vpc_cidr                          = local.own_vpc.vpc_cidr
      subnet_ids                        = local.own_vpc.private_subnet_ids
      subnet_route_table_ids            = local.own_vpc.private_route_table_ids
      route_to                          = null
      static_routes                     = var.static_routes
      transit_gateway_vpc_attachment_id = null
      route_to_cidr_blocks              = concat([for vpc in local.allowed_vpcs : vpc.cidr if !vpc.cross_region], var.static_tgw_routes)
    }
  }

  context = module.this.context
}

# Create a TGW attachment for a Peering Connection
# This in only necessary in the hub accounts
resource "aws_ec2_transit_gateway_route" "peering_connection" {
  for_each = local.is_network_hub ? {
    for vpc in local.cross_region_vpcs : vpc.cidr => vpc
  } : {}

  # Use the TGW Attachment in the alternate, peered region
  transit_gateway_attachment_id = var.peered_region ? var.tgw_connector_config[local.own_vpc.environment].outputs.aws_ec2_transit_gateway_peering_attachment_id : var.tgw_connector_config[each.value.environment].outputs.aws_ec2_transit_gateway_peering_attachment_id

  blackhole                      = false
  destination_cidr_block         = each.value.cidr
  transit_gateway_route_table_id = var.tgw_config.existing_transit_gateway_route_table_id
}

# Route this VPC to the destination CIDR
# This is only necessary in cross-region connections
resource "aws_route" "peering_connection" {
  for_each = {
    for vpc_rt in local.cross_region_vpc_route_table_ids : "${vpc_rt.route_table_id}:${vpc_rt.cidr}" => vpc_rt
  }

  transit_gateway_id = var.tgw_config.existing_transit_gateway_id

  route_table_id         = each.value.route_table_id
  destination_cidr_block = each.value.cidr
}

# Define a Security Group Rule to allow traffic from
# Expose traffic from EKS VPC CIDRs in other accounts to this accounts EKS cluster SG
resource "aws_security_group_rule" "ingress_cidr_blocks" {
  for_each = var.expose_eks_sg ? local.allowed_eks : {}

  description       = "Allow inbound traffic from ${each.key}"
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [each.value.cidr] # CIDR of cluster in other accounts
  security_group_id = each.value.sg_id  # SG of cluster in this account
}
