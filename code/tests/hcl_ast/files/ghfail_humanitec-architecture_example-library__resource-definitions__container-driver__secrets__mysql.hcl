resource "humanitec_resource_definition" "container-driver-secrets-example-mysql" {
  driver_type    = "humanitec/container"
  id             = "container-driver-secrets-example-mysql"
  name           = "container-driver-secrets-example-mysql"
  type           = "mysql"
  driver_account = "my-aws-cloud-account"
  driver_inputs = {
    values_string = jsonencode({
      "job"     = "$${resources['config.runner'].outputs.job}"
      "cluster" = "$${resources['config.runner'].outputs.cluster}"
      "credentials_config" = {
        "environment" = {
          "AWS_ACCESS_KEY_ID"     = "AccessKeyId"
          "AWS_SECRET_ACCESS_KEY" = "SecretAccessKey"
        }
      }
      "source" = {
        "ref" = "refs/heads/main"
        "url" = "https://github.com/my-org/my-repo.git"
      }
    })
    secret_refs = jsonencode({
      "job" = {
        "variables" = {
          "TF_VAR_mysql-instance-username" = {
            "value" = "$${resources['mysql-instance.default'].outputs.username}"
          }
          "TF_VAR_mysql-instance-password" = {
            "value" = "$${resources['mysql-instance.default'].outputs.password}"
          }
        }
      }
      "source" = {
        "password" = {
          "store" = "my-secret-store"
          "ref"   = "my-path-to-git-token"
        }
      }
    })
  }
}

resource "humanitec_resource_definition_criteria" "container-driver-secrets-example-mysql_criteria_0" {
  resource_definition_id = resource.humanitec_resource_definition.container-driver-secrets-example-mysql.id
  app_id                 = "container-driver-secrets-example"
}
