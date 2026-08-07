locals {
  terragrunt_modules = toset([
    for x in fileset(var.foundation_dir, "**/terragrunt.hcl") : trimsuffix(x, "/terragrunt.hcl")
    if(
      !strcontains(x, ".terragrunt-cache") && # this might not be required, check
      !strcontains(x, "/tenants/")            # we don't document individual tenants, though maybe we should?
    )
  ])

  terragrunt_to_kit_modules = {
    for key in local.terragrunt_modules :
    key => startswith(key, "platforms/")
    ? trimprefix(key, "platforms/") # platform module ids are relative to the platforms directory
    : "foundation/${key}"           # foundation modules are prefixed with foundation
  }

  platform_modules_azure = toset([for x in local.terragrunt_modules : x if startswith(x, "platforms/azure")])
}

data "terraform_remote_state" "docs_azure" {
  for_each = local.platform_modules_azure

  backend = "azurerm"
  config = {
    use_azuread_auth     = true
    tenant_id            = var.platforms.azure.aad_tenant_id
    subscription_id      = var.platforms.azure.subscription_id
    resource_group_name  = var.platforms.azure.tfstateconfig.resource_group_name
    storage_account_name = var.platforms.azure.tfstateconfig.storage_account_name
    container_name       = var.platforms.azure.tfstateconfig.container_name
    key                  = "${trimprefix(each.key, "platforms/azure/")}.tfstate"
  }
}

locals {
  kit_dir        = "${var.repo_dir}/kit"
  compliance_dir = "${var.repo_dir}/compliance"
}

locals {

  platform_readmes = fileset("${var.foundation_dir}/platforms", "*/README.md")

  kit_readmes = toset([
    for x in fileset(local.kit_dir, "**/README.md") : x
    if(
      !strcontains(x, ".terraform") &&
      !strcontains(x, ".terragrunt-cache")
    )
  ])

  parsed_kit_modules = { for x in local.kit_readmes :
    trimsuffix(x, "/README.md") => try(yamldecode(regex("^---([\\s\\S]*)\\n---\\n[\\s\\S]*$", file("${local.kit_dir}/${x}"))[0]), null)
  }

  compliance_readmes = toset([
    for x in fileset(local.compliance_dir, "**/*.md") : x
  ])

  parsed_compliance_controls = { for x in local.compliance_readmes :
    trimsuffix(x, ".md") => try(yamldecode(regex("^---([\\s\\S]*)\\n---\\n[\\s\\S]*$", file("${local.compliance_dir}/${x}"))[0]), null)
  }

  kit_modules = {
    for key, value in local.parsed_kit_modules :
    key => value

    if value != null
  }

  kit_module_compliance_md = {
    for key, value in local.kit_modules :
    key => join(
      "\n",
      compact([for s in try(value.compliance, []) : try(
        "- [${local.parsed_compliance_controls[s.control].name}](/compliance/${s.control}.md): ${trimspace(s.statement)}",
        "<!-- error locating compliance control ${s.control} -->"
      )])
    )
  }
}

resource "null_resource" "copy_template" {
  triggers = {
    output_dir         = var.output_dir
    template_dir_files = join(" ", fileset(var.template_dir, "**/*")) # since we use symbolic links, we don't care for file content
  }

  provisioner "local-exec" {
    when = create
    # copy files as symbolic links, this means we can change them in the source dir and live reload will work!
    command = "mkdir -p ${var.output_dir} && cp -a -R -L ${var.template_dir}/* ${var.output_dir}"
  }

  provisioner "local-exec" {
    when = destroy
    # remove symbolic links
    command = "cd ${self.triggers.output_dir} && rm -f ${self.triggers.template_dir_files}"
  }
}

resource "null_resource" "copy_compliance" {
  triggers = {
    output_dir         = var.output_dir
    template_dir_files = join(" ", fileset(local.compliance_dir, "**/*")) # since we use symbolic links, we don't care for file content
  }

  provisioner "local-exec" {
    when = create
    # copy files as symbolic links, this means we can change them in the source dir and live reload will work!
    command = "mkdir -p ${var.output_dir}/docs/compliance && cp -a -R -L ${local.compliance_dir}/* ${var.output_dir}/docs/compliance"
  }

  provisioner "local-exec" {
    when = destroy
    # remove symbolic links
    command = "cd ${self.triggers.output_dir}/docs/compliance && rm -f ${self.triggers.template_dir_files}"
  }
}

resource "local_file" "module_docs" {
  depends_on = [null_resource.copy_template]
  for_each   = local.terragrunt_modules

  filename = "${var.output_dir}/docs/${each.key}.md"
  content = join(
    "\n\n",
    compact([
      # documentation_md
      try(data.terraform_remote_state.docs_azure[each.key].outputs.documentation_md, "*no `docmentation_md` output provided*"),
      # by convention, we expect that a platform module uses the same kit module name so we use that to lookup compliance statements
      "## Compliance Statements",
      coalesce(
        try(local.kit_module_compliance_md[local.terragrunt_to_kit_modules[each.key]], null),
        "*no compliance statements provided*"
      )
    ])
  )
}

# todo: not sure we want those
resource "local_file" "platform_readmes" {
  depends_on = [null_resource.copy_template]
  for_each   = local.platform_readmes

  filename = "${var.output_dir}/docs/platforms/${each.key}"
  content  = file("${var.foundation_dir}/platforms/${each.key}")
}

# locals {
#   guides = try(data.terraform_remote_state.docs["meshstack"].outputs.documentation_guides_md, {})
# }

# resource "local_file" "meshstack_guides" {
#   depends_on = [null_resource.copy_template]
#   for_each   = local.guides

#   filename = "${var.output_dir}/docs/meshstack/guides/${each.key}.md"
#   content  = each.value
# }
