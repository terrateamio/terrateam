locals {
  # NOTE: do not include branch name here as only underscore and alphanumeric allowed
  team_ami_base_name = join("_", [var.team_name, var.ami_base_name])

  ami_name = join("_", flatten([
    local.team_ami_base_name,
    var.release_or_patch == "" ? [] : [var.release_or_patch],
    "{{ imagebuilder:buildDate }}"
  ]))

  account_id = data.aws_caller_identity.current.account_id

  kms_key_id = data.aws_kms_key.hmpps_ebs_encryption_cmk.arn

  core_shared_services = {
    repo_tfstate            = data.terraform_remote_state.core_shared_services_production.outputs
    imagebuilder_mp_tfstate = data.terraform_remote_state.imagebuilder_mp.outputs
  }

  components_custom_data = {
    for component in var.components_custom :
    component.path => length(regexall(".*tftpl", component.path)) > 0 ?
    templatefile(component.path, var.component_template_args) :
    file(component.path)
  }

  components_custom_yaml = {
    for component_filename, data in local.components_custom_data :
    basename(component_filename) => {
      raw  = data
      yaml = yamldecode(replace(data, "!Ref ", "")) # stop yamldecode breaking from cloudformation specific syntax. Not trusted cf.
    }
  }

  components_custom_versions = {
    for component_filename, data in local.components_custom_yaml :
    "${data.yaml.name}-version" => data.yaml.parameters[0].Version.default
  }

  components_aws_versions = {
    for component_aws in var.components_aws :
    "${component_aws}-version" => data.aws_imagebuilder_component.this[component_aws].version
  }

  component_version_tags = merge(local.components_custom_versions, local.components_aws_versions)

  default_tags = {
    image-pipeline               = local.team_ami_base_name
    image-recipe                 = join("/", [local.team_ami_base_name, var.configuration_version])
    infrastructure-configuration = join("/", [local.team_ami_base_name, var.configuration_version])
    release-or-patch             = var.release_or_patch == "" ? "n/a" : var.release_or_patch
  }

  tags = merge(
    local.default_tags,
    local.component_version_tags,
    var.tags
  )

  ami_tags = merge(local.tags, {
    Name = local.ami_name
  })

  environment_management = jsondecode(data.aws_secretsmanager_secret_version.environment_management.secret_string)

  account_ids_lookup = local.environment_management.account_ids

  ami_parent_id  = try(local.account_ids_lookup[var.parent_image.owner], var.parent_image.owner)
  ami_parent_arn = try("arn:aws:imagebuilder:${var.region}:${local.ami_parent_id}:image/${var.parent_image.arn_resource_id}", null)

  accounts_to_distribute_ami = distinct(flatten([
    var.account_to_distribute_ami != null ? [var.account_to_distribute_ami] : [],
    var.accounts_to_distribute_ami
  ]))
}

