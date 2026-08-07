locals {
  custom_backends        = ["none", "bypass", "static"]
  is_data_source_backend = !contains(local.custom_backends, local.backend_type)

  remote_workspace = var.workspace != null ? var.workspace : local.workspace
  ds_backend       = local.is_data_source_backend ? local.backend_type : "none"
  ds_workspace     = local.ds_backend == "none" ? null : local.remote_workspace

  # The `privileged` flag is no longer used in the Cloud Posse reference architecture, but is maintained for compatibility.
  # This was and is only supported for the S3 backend.
  #
  # When the `privileged` flag is set to `true`, the user running Terraform is considered privileged and therefore
  # does not need to assume a different role to access the S3 backend.
  #
  # This is accomplished by removing any profile or role ARN settings from the configuration.
  s3_privileged_backend = { for k, v in local.backend : k => v if !contains(["profile", "role_arn", "assume_role", "assume_role_with_web_identity"], k) }

  # Workaround for the fact that the 2 different backends can be different types,
  # but both results of a conditional must be the same type.
  s3_backend = {
    # normal, not privileged
    false = local.backend
    # privileged
    true = local.s3_privileged_backend
  }

  # Customize certain configurations. Otherwise we will just use whatever was configured in the stack.
  ds_configurations = {
    # If no valid configuration is found for the backend datasource, provide a dummy one.
    none = {
      path = "${path.module}/dummy-remote-state.json"
    }

    remote = merge(local.backend, {
      workspaces = {
        name = local.remote_workspace
      }
    })

    s3 = local.s3_backend[var.privileged]
  } # ds_configurations

}

data "terraform_remote_state" "data_source" {
  count = var.bypass ? 0 : 1

  # Use a dummy local backend when the real backend is not supported by the data source
  backend   = local.ds_backend == "none" ? "local" : local.ds_backend
  workspace = local.ds_workspace
  # If nothing needs to be customized, just use whatever was configured in the stack
  config   = lookup(local.ds_configurations, local.ds_backend, local.backend)
  defaults = var.defaults
}
