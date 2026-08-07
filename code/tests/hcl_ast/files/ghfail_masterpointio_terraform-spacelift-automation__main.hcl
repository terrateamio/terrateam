# This Terraform code automates the creation and management of Spacelift stacks based on the structure
# and configurations defined in the Git repository, default Stack values and additional input variables.
# It primarily relies on dynamic local expressions to generate configurations based on the
# input variables and Git structure so it can be consumed by Spacelift resources.
# This module can also manage the automation stack itself, but it should be bootstrapped manually.
#
# It handles the following:
#
# 1. Stack Configurations (see ## Stack Configurations)
# Reads the Spacelift stack configurations strictly based on the root modules structure in Git and file names.
# These are the configurations required to be set for a stack, e.g. project_root, terraform_workspace, root_module.
#
# 2. Common Stack configurations (see ## Common Stack configurations)
# Some configurations are equal across the whole root module, and can be set it on a root module level:
# * Space IDs: in the majority of cases all the workspaces in a root module belong to the same Spacelift space, so
# we allow setting a "global" space_id for all stacks on a root module level.
# * Autodeploy: if all the stacks in a root module should be autodeployed.
# * Administrative: if all the stacks in a root module are administrative, e.g stacks that manage Spacelift resources.
#
# 3. Labels (see ## Labels)
# Generates labels for the stacks based on administrative, dependency, and folder information.
#
# Syntax note:
# The local expression started with an underscore `_` is used to store intermediate values
# that are not directly used in the resource creation.

locals {
  # Constants
  default_workspace_name = "default"
  root_space_id          = "root"

  _multi_instance_structure = var.root_module_structure == "MultiInstance"

  # Read all stack files following the associated root_module_structure convention:
  # MultiInstance: root-module-name/stacks/*.yaml
  # SingleInstance: root-module-name/stack.yaml
  # Example:
  # [
  # MultiInstance:
  #   "../root-module-a/stacks/example.yaml",
  #   "../root-module-a/stacks/common.yaml",
  #   "../root-module-b/stacks/example.yaml",
  #   "../root-module-b/stacks/common.yaml",
  # ] OR [
  # SingleInstance:
  #   "../root-module-a/stack.yaml",
  #   "../root-module-b/stack.yaml",
  # ]
  #   "../root-module-a/stacks/example.yaml",
  #   "../root-module-a/stacks/common.yaml",
  #   "../root-module-b/stacks/example.yaml",
  #   "../root-module-b/stacks/common.yaml",
  # ] OR [
  #   "../root-module-a/stack.yaml",
  #   "../root-module-b/stack.yaml",
  # ]
  # This includes nested directories, example: [
  #   "../ecs-infrastructure/service-1/stacks/example.yaml",
  #   "../ecs-infrastructure/service-1/stacks/common.yaml",
  #   "../data-infrastructure/redshift-clusters/financial-reporting/stacks/example.yaml",
  #   "../data-infrastructure/redshift-clusters/bi-reporting/stacks/example.yaml",
  # ]
  _multi_instance_stack_files_raw  = fileset("${path.root}/${var.root_modules_path}", "**/stacks/*.yaml")
  _single_instance_stack_files_raw = fileset("${path.root}/${var.root_modules_path}", "**/stack.yaml")

  # Filter out any files that are in .terraform directories to avoid picking up module cache now that it's using ** as the wildcard
  _multi_instance_stack_files  = [for file in local._multi_instance_stack_files_raw : file if !can(regex("\\.terraform/", file))]
  _single_instance_stack_files = [for file in local._single_instance_stack_files_raw : file if !can(regex("\\.terraform/", file))]
  _all_stack_files             = local._multi_instance_structure ? local._multi_instance_stack_files : local._single_instance_stack_files

  # Extract the root module name from the stack file path
  # For MultiInstance: extract path before "/stacks" to get the full nested path
  # For SingleInstance: extract directory path to get the full nested path
  _all_root_modules = distinct([
    for file in local._all_stack_files :
    local._multi_instance_structure ?
    dirname(dirname(file)) : # For MultiInstance: example2/nested/stacks/stack.yaml -> example2/nested
    dirname(file)            # For SingleInstance: example2/nested/stack.yaml -> example2/nested
  ])

  # If all root modules are enabled, use all root modules, otherwise use only those given to us
  enabled_root_modules = var.all_root_modules_enabled ? local._all_root_modules : var.enabled_root_modules

  # Read and decode Stack YAML files from the root directory
  # Example:
  # MultiInstance: {
  #   "random-pet" = {
  #     "common.yaml" = {
  #       "stack_settings" = { ... }
  #       ...
  #     }
  #     "example.yaml" = {
  #       "stack_settings" = { ... }
  #       ...
  #     }
  #   }
  # }
  # SingleInstance: {
  #   "random-pet" = {
  #     "default" = { stack_settings = { ... }, ... }
  #   }
  # }
  _multi_instance_root_module_yaml_decoded = {
    for module in local.enabled_root_modules : module => {
      for yaml_file in fileset("${path.root}/${var.root_modules_path}/${module}/stacks", "*.yaml") :
      yaml_file => yamldecode(file("${path.root}/${var.root_modules_path}/${module}/stacks/${yaml_file}"))
    } if local._multi_instance_structure
  }

  _single_instance_root_module_yaml_decoded = {
    for module in local.enabled_root_modules : module => {
      (local.default_workspace_name) = yamldecode(file("${path.root}/${var.root_modules_path}/${module}/stack.yaml"))
    } if !local._multi_instance_structure
  }

  _root_module_yaml_decoded = merge(local._multi_instance_root_module_yaml_decoded, local._single_instance_root_module_yaml_decoded)

  ## Common Stack configurations
  # Retrieve common Stack configurations for each root module.
  # SingleInstance root_module_structure does not support common configs today.
  # Example:
  # {
  #   "random-pet" = {
  #     "stack_settings" = {
  #       "description" = "This stack generates random pet names"
  #       "manage_state" = true
  #     }
  #     "tfvars" = {
  #       "enabled" = false
  #     }
  #   }
  # }
  _common_configs = {
    for module, files in local._root_module_yaml_decoded : module => lookup(files, var.common_config_file, {})
  }

  # If we're SingleInstance, then default_tf_workspace_enabled is true. Otherwise, use given value.
  _default_tf_workspace_enabled = local._multi_instance_structure ? var.default_tf_workspace_enabled : true

  ## Stack Configurations
  # Merge all Stack configurations from the root modules into a single map, and filter out the common config.
  # Example:
  # {
  #   "random-pet-example" = {
  #     "project_root" = "examples/complete/root-modules/random-pet"
  #     "root_module" = "random-pet"
  #     "stack_settings" = {
  #       "manage_state" = true
  #     }
  #     "terraform_workspace" = "example"
  #     "tfvars" = {
  #       "enabled" = true
  #     }
  #   }
  # }
  _root_module_stack_configs = merge([for module, files in local._root_module_yaml_decoded : {
    for file, content in files :
    local._multi_instance_structure ? "${module}-${trimsuffix(file, ".yaml")}" : module =>
    merge(
      {
        # Use specified project_root, if not, build it using the root_modules_path and module name
        "project_root" = try(content.stack_settings.project_root, replace(format("%s/%s", var.root_modules_path, module), "../", "")),
        "root_module"  = module,

        # If default_tf_workspace_enabled is true, use "default" workspace, otherwise our file name is the workspace name
        "terraform_workspace" = try(content.automation_settings.default_tf_workspace_enabled, local._default_tf_workspace_enabled) ? local.default_workspace_name : trimsuffix(file, ".yaml"),

        # tfvars_file_name only pertains to MultiInstance, as SingleInstance expects consumers to use an auto.tfvars file.
        # `yaml` is intentionally used here as we require Stack and `tfvars` config files to be named equally
        "tfvars_file_name" = trimsuffix(file, ".yaml"),
      },
      content,
    ) if file != var.common_config_file
    }
  ]...)

  # Get the configs for each stack, merged with the common configurations
  # Example:
  # {
  #   "random-pet-example" = {
  #     "project_root" = "examples/complete/root-modules/random-pet"
  #     "root_module" = "random-pet"
  #     "stack_settings" = {
  #       "manage_state" = true
  #     }
  #     "terraform_workspace" = "example"
  #     "tfvars" = {
  #       "enabled" = false
  #     }
  #   }
  # }
  configs = {
    for key, value in module.deep : key => value.merged
  }

  # Get the Stacks configs, this is just to improve code readability
  # Example:
  # {
  #   "random-pet-example" = {
  #     "manage_state" = true
  #   }
  # }
  stack_configs = {
    for key, value in local.configs : key => value.stack_settings
  }

  # Get the list of all stack names
  stacks = toset(keys(local.stack_configs))

  ## Labels
  # Creates a map of `depends-on` labels for each stack based on the root module level dependency configuration.
  # Example:
  # {
  #   "random-pet-example" = [
  #     "depends-on:spacelift-automation-default",
  #   ]
  # }
  _dependency_labels = {
    for stack in local.stacks : stack => [
      "depends-on:spacelift-automation-${terraform.workspace}"
    ] if var.dependency_labels_enabled
  }

  # Creates a map of folder labels for each stack based on Git structure for a proper grouping stacks in Spacelift UI.
  # https://docs.spacelift.io/concepts/stack/organizing-stacks#label-based-folders
  # Example:
  # {
  #   "random-pet-example" = [
  #     "folder:random-pet/example",
  #   ]
  # }
  _folder_labels = {
    for stack in local.stacks : stack => [
      local._multi_instance_structure ? "folder:${local.configs[stack].root_module}/${local.configs[stack].tfvars_file_name}" : "folder:${local.configs[stack].root_module}"
    ]
  }

  # Merge all the labels into a single map for each stack.
  # Example:
  # {
  #   "random-pet-example" = tolist([
  #     "folder:random-pet/example",
  #     "depends-on:spacelift-automation-default",
  #   ])
  # }
  labels = {
    for stack in local.stacks :
    stack => compact(flatten([
      lookup(local._folder_labels, stack, []),
      lookup(local._dependency_labels, stack, []),
      try(local.stack_configs[stack].labels, []),
      var.labels,
    ]))
  }

  # Merge all before_init steps into a single map for each stack.
  before_init = {
    for stack in local.stacks : stack =>
    # tfvars are implicitly enabled in MultiInstance, which means we include the tfvars copy command in before_init
    # In SingleInstance, we expect the consumer to use an auto.tfvars file, so we don't include the tfvars copy command in before_init
    try(local.configs[stack].automation_settings.tfvars_enabled, local._multi_instance_structure) ?
    compact(concat(
      var.before_init,
      try(local.stack_configs[stack].before_init, []),
      # This command is required for each stack.
      # It copies the tfvars file from the stack's workspace to the root module's directory
      # and renames it to `spacelift.auto.tfvars` to automatically load variable definitions for each run/task.
      ["cp tfvars/${local.configs[stack].tfvars_file_name}.tfvars spacelift.auto.tfvars"],
      )) : compact(concat(
      var.before_init,
      try(local.stack_configs[stack].before_init, []),
    ))
  }

  # Helper for property resolution with fallback to defaults
  stack_property_resolver = {
    for stack in local.stacks : stack => {
      # Simple property resolution with fallback
      autoretry                        = try(local.stack_configs[stack].autoretry, var.autoretry)
      additional_project_globs         = try(local.stack_configs[stack].additional_project_globs, var.additional_project_globs)
      autodeploy                       = try(local.stack_configs[stack].autodeploy, var.autodeploy)
      branch                           = try(local.stack_configs[stack].branch, var.branch)
      enable_local_preview             = try(local.stack_configs[stack].enable_local_preview, var.enable_local_preview)
      enable_well_known_secret_masking = try(local.stack_configs[stack].enable_well_known_secret_masking, var.enable_well_known_secret_masking)
      github_action_deploy             = try(local.stack_configs[stack].github_action_deploy, var.github_action_deploy)
      manage_state                     = try(local.stack_configs[stack].manage_state, var.manage_state)
      protect_from_deletion            = try(local.stack_configs[stack].protect_from_deletion, var.protect_from_deletion)
      repository                       = try(local.stack_configs[stack].repository, var.repository)
      runner_image                     = try(local.stack_configs[stack].runner_image, var.runner_image)
      terraform_smart_sanitization     = try(local.stack_configs[stack].terraform_smart_sanitization, var.terraform_smart_sanitization)
      terraform_version                = try(local.stack_configs[stack].terraform_version, var.terraform_version)
      worker_pool_id                   = try(local.stack_configs[stack].worker_pool_id, var.worker_pool_id)

      # AWS Integration properties
      aws_integration_id = local.resource_id_resolver.aws_integration[stack]

      # Drift detection properties
      drift_detection_ignore_state = try(local.stack_configs[stack].drift_detection_ignore_state, var.drift_detection_ignore_state)
      drift_detection_reconcile    = try(local.stack_configs[stack].drift_detection_reconcile, var.drift_detection_reconcile)
      drift_detection_schedule     = try(local.stack_configs[stack].drift_detection_schedule, var.drift_detection_schedule)
      drift_detection_timezone     = try(local.stack_configs[stack].drift_detection_timezone, var.drift_detection_timezone)

      # Destructor properties
      destructor_deactivated = try(local.stack_configs[stack].destructor_deactivated, var.destructor_deactivated)
    }
  }

  # Helper for array merging with fallback
  stack_array_merger = {
    for stack in local.stacks : stack => {
      after_apply    = compact(concat(try(local.stack_configs[stack].after_apply, []), var.after_apply))
      after_destroy  = compact(concat(try(local.stack_configs[stack].after_destroy, []), var.after_destroy))
      after_init     = compact(concat(try(local.stack_configs[stack].after_init, []), var.after_init))
      after_perform  = compact(concat(try(local.stack_configs[stack].after_perform, []), var.after_perform))
      after_plan     = compact(concat(try(local.stack_configs[stack].after_plan, []), var.after_plan))
      after_run      = compact(concat(try(local.stack_configs[stack].after_run, []), var.after_run))
      before_apply   = compact(concat(try(local.stack_configs[stack].before_apply, []), var.before_apply))
      before_destroy = compact(concat(try(local.stack_configs[stack].before_destroy, []), var.before_destroy))
      before_perform = compact(concat(try(local.stack_configs[stack].before_perform, []), var.before_perform))
      before_plan    = compact(concat(try(local.stack_configs[stack].before_plan, []), var.before_plan))
    }
  }

  ###############
  # Resource Name to ID Resolver
  #(e.g. space_name -> space_id so users can use the human readable name rather than the ID in configs)
  ###############
  name_to_id_mappings = {
    space = {
      for space in data.spacelift_spaces.all.spaces :
      space.name => space.space_id
    }
    worker_pool = {
      for pool in data.spacelift_worker_pools.all.worker_pools :
      pool.name => pool.worker_pool_id
    }
    aws_integration = {
      for integration in data.spacelift_aws_integrations.all.integrations :
      integration.name => integration.integration_id
    }
  }

  resource_id_resolver_config = {
    space = {
      id_attr       = "space_id"
      name_attr     = "space_name"
      default_value = local.root_space_id
    }
    worker_pool = {
      id_attr       = "worker_pool_id"
      name_attr     = "worker_pool_name"
      default_value = null
    }
    aws_integration = {
      id_attr       = "aws_integration_id"
      name_attr     = "aws_integration_name"
      default_value = null
    }
  }

  var_lookup = { # We need this map to dynamically access vars like var.space_id when config.id_attr = "space_id". TF doesn't support var[dynamic_key] syntax, downside of it not being a full programming language.
    space_id             = var.space_id
    space_name           = var.space_name
    worker_pool_id       = var.worker_pool_id
    worker_pool_name     = var.worker_pool_name
    aws_integration_id   = var.aws_integration_id
    aws_integration_name = var.aws_integration_name
  }

  # How it works:
  # 1. Loops through each resource type (space, worker_pool, aws_integration)
  # 2. For each stack, tries to resolve the ID using coalesce() with this precedence: stack ID > stack name > global ID > global name > default
  # Example for space resolution on stack "my-stack":
  # 1. Check local.stack_configs["my-stack"]["space_id"] (direct ID from YAML)
  # 2. Check local.name_to_id_mappings["space"][local.stack_configs["my-stack"]["space_name"]] (name→ID from YAML)
  # 3. Check var.space_id (global module variable)
  # 4. Check local.name_to_id_mappings["space"][var.space_name] (global name→ID)
  # 5. Fall back to local.root_space_id ("root")
  resource_id_resolver = {
    for resource_type, config in local.resource_id_resolver_config : resource_type => {
      for stack in local.stacks : stack => try(coalesce(
        try(local.stack_configs[stack][config.id_attr], null),                                             # Direct stack-level ID always takes precedence
        try(local.name_to_id_mappings[resource_type][local.stack_configs[stack][config.name_attr]], null), # Direct stack-level name resolution
        local.var_lookup[config.id_attr],                                                                  # Global variable ID
        try(local.name_to_id_mappings[resource_type][local.var_lookup[config.name_attr]], null),           # Global variable name resolution
      ), config.default_value)                                                                             # Resource-specific default
    }
  }

  ## Filter integration + drift detection stacks

  aws_integration_stacks = {
    for stack, config in local.stack_configs :
    stack => config if try(config.aws_integration_enabled, var.aws_integration_enabled)
  }
  drift_detection_stacks = {
    for stack, config in local.stack_configs :
    stack => config if try(config.drift_detection_enabled, var.drift_detection_enabled)
  }
  destructor_stacks = {
    for stack, config in local.stack_configs :
    stack => config if try(config.destructor_enabled, var.destructor_enabled)
  }

  # Filter stacks that need a Spacelift role attached (replaces the deprecated administrative flag).
  # A role attachment is created when a per-stack `role_attachment_role_slug` is set in the stack's
  # YAML config, OR when the module-level `var.role_attachment` is configured (applies to all stacks).
  role_attachment_stacks = {
    for stack, config in local.stack_configs :
    stack => config if try(config.role_attachment_role_slug, null) != null || var.role_attachment != null
  }

  # Collect the unique role slugs/keys needed across all role attachment stacks so we can look them up once.
  # role_attachment_role_slug is required — either per-stack in YAML or via var.role_attachment.role_slug.
  _role_attachment_slugs = toset([
    for stack in keys(local.role_attachment_stacks) :
    try(local.stack_configs[stack].role_attachment_role_slug, var.role_attachment.role_slug)
  ])

  # Exclude managed role keys from the data source lookup — those roles are resolved directly
  # from spacelift_role.managed, so we don't need (and can't) look them up via data source.
  _external_role_attachment_slugs = toset([
    for slug in local._role_attachment_slugs : slug
    if !contains(keys(var.managed_roles), slug)
  ])

  # Unified key/slug → role ID map used by spacelift_role_attachment.
  # Managed roles (keyed by var.managed_roles map key) take precedence, external roles
  # are keyed by their Spacelift slug as looked up via data.spacelift_role.attachments.
  _role_slug_to_id = merge(
    { for slug, role in data.spacelift_role.attachments : slug => role.id },
    { for key, role in spacelift_role.managed : key => role.id },
  )
}


# Perform deep merge for common configurations and stack configurations
module "deep" {
  source   = "cloudposse/config/yaml//modules/deepmerge"
  version  = "1.0.2"
  for_each = local._root_module_stack_configs

  # Here is where some magic happens...
  # The common config is the base config, it is overridden by the static StackConfig
  # Runtime overrides are applied last (should be used sparingly), they overwrite all values for the Stack
  maps = [
    local._common_configs[each.value.root_module],
    each.value,
    try(jsondecode(data.jsonschema_validator.runtime_overrides[each.value.root_module].validated), {}),
  ]

  # To support merging labels from common.yaml, we need lists to append instead of overwrite
  append_list_enabled = true
}

resource "spacelift_stack" "default" {
  for_each = local.stacks

  additional_project_globs = local.stack_property_resolver[each.key].additional_project_globs
  after_apply              = local.stack_array_merger[each.key].after_apply
  after_destroy            = local.stack_array_merger[each.key].after_destroy
  after_init               = local.stack_array_merger[each.key].after_init
  after_perform            = local.stack_array_merger[each.key].after_perform
  after_plan               = local.stack_array_merger[each.key].after_plan
  after_run                = local.stack_array_merger[each.key].after_run
  autodeploy               = local.stack_property_resolver[each.key].autodeploy
  autoretry                = local.stack_property_resolver[each.key].autoretry
  before_apply             = local.stack_array_merger[each.key].before_apply
  before_destroy           = local.stack_array_merger[each.key].before_destroy
  # before_init is handled separately from other script arrays due to special tfvars logic
  # See local.before_init for details on tfvars file copying and MultiInstance vs SingleInstance handling
  before_init                      = local.before_init[each.key]
  before_perform                   = local.stack_array_merger[each.key].before_perform
  before_plan                      = local.stack_array_merger[each.key].before_plan
  branch                           = local.stack_property_resolver[each.key].branch
  enable_local_preview             = local.stack_property_resolver[each.key].enable_local_preview
  enable_well_known_secret_masking = local.stack_property_resolver[each.key].enable_well_known_secret_masking
  github_action_deploy             = local.stack_property_resolver[each.key].github_action_deploy
  labels                           = local.labels[each.key]
  manage_state                     = local.stack_property_resolver[each.key].manage_state
  name                             = each.key
  project_root                     = local.configs[each.key].project_root
  protect_from_deletion            = local.stack_property_resolver[each.key].protect_from_deletion
  repository                       = local.stack_property_resolver[each.key].repository
  runner_image                     = local.stack_property_resolver[each.key].runner_image
  space_id                         = local.resource_id_resolver.space[each.key]
  terraform_smart_sanitization     = local.stack_property_resolver[each.key].terraform_smart_sanitization
  terraform_version                = local.stack_property_resolver[each.key].terraform_version
  terraform_workflow_tool          = var.terraform_workflow_tool
  terraform_workspace              = local.configs[each.key].terraform_workspace
  worker_pool_id                   = local.resource_id_resolver.worker_pool[each.key]

  # Usage of `templatestring` requires OpenTofu 1.7 and Terraform 1.9 or later.
  description = coalesce(
    try(local.stack_configs[each.key].description, null),
    try(templatestring(var.description, local.configs[each.key]), null),
    "Managed by spacelift-automation Terraform root module."
  )

  dynamic "github_enterprise" {
    for_each = var.github_enterprise != null ? [var.github_enterprise] : []
    content {
      namespace = github_enterprise.value["namespace"]
      id        = try(github_enterprise.value["id"], null)
    }
  }

  dynamic "azure_devops" {
    for_each = var.azure_devops != null ? [var.azure_devops] : []
    content {
      project = azure_devops.value["project"]
      id      = try(azure_devops.value["id"], null)
    }
  }

  dynamic "raw_git" {
    for_each = var.raw_git != null ? [var.raw_git] : []
    content {
      namespace = raw_git.value["namespace"]
      url       = raw_git.value["url"]
    }
  }

  dynamic "gitlab" {
    for_each = var.gitlab != null ? [var.gitlab] : []
    content {
      namespace = gitlab.value["namespace"]
      id        = try(gitlab.value["id"], null)
    }
  }

  dynamic "bitbucket_cloud" {
    for_each = var.bitbucket_cloud != null ? [var.bitbucket_cloud] : []
    content {
      namespace = bitbucket_cloud.value["namespace"]
      id        = try(bitbucket_cloud.value["id"], null)
    }
  }

  dynamic "bitbucket_datacenter" {
    for_each = var.bitbucket_datacenter != null ? [var.bitbucket_datacenter] : []
    content {
      namespace = bitbucket_datacenter.value["namespace"]
      id        = try(bitbucket_datacenter.value["id"], null)
    }
  }
}

# The Spacelift Destructor is a feature designed to automatically clean up the resources no longer managed by our IaC.
# Don't toggle the creation/destruction of this resource with var.destructor_enabled,
# as it will delete all resources in the stack when toggled from 'true' to 'false'.
# Use the 'deactivated' attribute to disable the stack destructor functionality instead.
# https://github.com/spacelift-io/terraform-provider-spacelift/blob/master/spacelift/resource_stack_destructor.go
resource "spacelift_stack_destructor" "default" {
  for_each = local.destructor_stacks

  stack_id    = spacelift_stack.default[each.key].id
  deactivated = local.stack_property_resolver[each.key].destructor_deactivated

  # `depends_on` should be used to make sure that all necessary resources (environment variables, roles, integrations, etc.)
  # are still in place when the destruction run is executed.
  # See https://registry.terraform.io/providers/spacelift-io/spacelift/latest/docs/resources/stack_destructor
  depends_on = [
    spacelift_drift_detection.default,
    spacelift_aws_integration_attachment.default
  ]
}

resource "spacelift_aws_integration_attachment" "default" {
  for_each = local.aws_integration_stacks

  integration_id = local.stack_property_resolver[each.key].aws_integration_id
  stack_id       = spacelift_stack.default[each.key].id
  read           = var.aws_integration_attachment_read
  write          = var.aws_integration_attachment_write
}

resource "spacelift_drift_detection" "default" {
  for_each = local.drift_detection_stacks

  stack_id     = spacelift_stack.default[each.key].id
  ignore_state = local.stack_property_resolver[each.key].drift_detection_ignore_state
  reconcile    = local.stack_property_resolver[each.key].drift_detection_reconcile
  schedule     = local.stack_property_resolver[each.key].drift_detection_schedule
  timezone     = local.stack_property_resolver[each.key].drift_detection_timezone

  lifecycle {
    precondition {
      condition     = alltrue([for schedule in local.stack_property_resolver[each.key].drift_detection_schedule : can(regex("^([0-9,\\-*/]+\\s+){4}[0-9,\\-*/]+$", schedule))])
      error_message = "Invalid cron schedule format for drift detection"
    }
  }
}

resource "spacelift_role" "managed" {
  for_each = var.managed_roles

  name        = each.value.name
  description = each.value.description
  actions     = each.value.actions
}

resource "spacelift_space" "default" {
  for_each = var.spaces

  name             = each.key
  description      = each.value.description
  inherit_entities = each.value.inherit_entities
  labels           = each.value.labels
  parent_space_id  = each.value.parent_space_id
}

# Attach a Spacelift role to stacks that have role_attachment_role_slug set (per-stack or module-level).
# This replaces the deprecated `administrative = true` flag.
# The role slug must be provided explicitly via per-stack `role_attachment_role_slug` in YAML
# or via the module-level `var.role_attachment.role_slug`. Use `role_attachment_space_id`
# (per-stack or module-level) to attach in a space other than the stack's own space.
resource "spacelift_role_attachment" "default" {
  for_each = local.role_attachment_stacks

  stack_id = spacelift_stack.default[each.key].id

  # Precedence: per-stack space_id → module-level space_id → stack's own space
  space_id = coalesce(
    try(local.stack_configs[each.key].role_attachment_space_id, null),
    try(var.role_attachment.space_id, null),
    spacelift_stack.default[each.key].space_id,
  )

  role_id = local._role_slug_to_id[
    try(local.stack_configs[each.key].role_attachment_role_slug, var.role_attachment.role_slug)
  ]
}
