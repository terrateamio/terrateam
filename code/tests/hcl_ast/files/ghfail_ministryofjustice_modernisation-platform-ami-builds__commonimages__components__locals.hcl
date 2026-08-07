locals {
  component_template_args = {}

  environment_management = jsondecode(data.aws_secretsmanager_secret_version.environment_management.secret_string)

  components_data = {
    for component_filename in fileset("templates", "*") :
    component_filename => length(regexall(".*tftpl", component_filename)) > 0 ?
    templatefile(component_filename, local.component_template_args) :
    file("templates/${component_filename}")
  }

  components_yaml = {
    for component_filename, data in local.components_data :
    component_filename => {
      raw  = data
      yaml = yamldecode(data)
    }
  }

  tags = {
    owner         = "digital-studio-operations-team@digital.justice.gov.uk"
    business-unit = "HMPPS"
    application   = "n/a"
    branch        = var.BRANCH_NAME == "" ? "n/a" : var.BRANCH_NAME
    is-production = var.BRANCH_NAME == "main" ? "true" : "false"
    source-code   = "https://github.com/ministryofjustice/modernisation-platform-ami-builds/tree/main/commonimages/components"
  }

}
