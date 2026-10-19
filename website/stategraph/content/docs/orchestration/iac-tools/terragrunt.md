---
title: Terragrunt
description: Run Terragrunt through Stategraph Orchestration. Set the engine, trigger runs on terragrunt.hcl changes, and auto-discover modules in large monorepos.
order: 3
---

Stategraph Orchestration runs Terragrunt in place of Terraform, with the same pull request plans, approvals, and applies. [Terragrunt](https://terragrunt.gruntwork.io/) is a thin wrapper around Terraform that keeps configurations DRY, works across many modules, and manages remote state.

## Enable Terragrunt

The [engine](/docs/reference/orchestration/configuration/engine) key sets the tool that Orchestration runs: Terraform, OpenTofu, the `stategraph` CLI, Terragrunt, Pulumi, CDKTF, or a custom command. This example in `.stategraph/config.yml` sets Terragrunt at a specific version, and starts a run when a `terragrunt.hcl` file changes, except the root `terragrunt.hcl`:

```yaml
engine:
  name: terragrunt
  version: 0.69.3
dirs:
  "**/terragrunt.hcl":
    when_modified:
      file_patterns: ['${DIR}/terragrunt.hcl']
  '.':
    when_modified:
      file_patterns: []
```

You can also set the engine on a workflow:

```yaml
dirs:
  "**/terragrunt.hcl":
    when_modified:
      file_patterns: ['${DIR}/terragrunt.hcl']
  '.':
    when_modified:
      file_patterns: []
workflows:
  - tag_query: ""
    engine:
      name: terragrunt
```

With either configuration, Orchestration runs `terragrunt` in place of `terraform` in each plan and apply. Terragrunt runs Terraform, or OpenTofu when you set `tf_cmd: tofu` on the engine.

Orchestration then detects changes to `terragrunt.hcl` files in pull requests, and runs the plans and applies that your configuration sets.

## Example repository and modules

Gruntwork's [infrastructure-live](https://github.com/gruntwork-io/terragrunt-infrastructure-live-example) repository shows a real-world Terragrunt layout. Use it as a starting point.

It pulls modules from the [terragrunt-infrastructure-modules-example](https://github.com/gruntwork-io/terragrunt-infrastructure-modules-example) repository. The `base_source_url` definitions are in the [envcommon](https://github.com/gruntwork-io/terragrunt-infrastructure-live-example/tree/master/_envcommon) `terragrunt.hcl` files. You can keep using that repository, but mirror it into your own GitHub organization or GitLab group, and point `base_source_url` at the mirror.

!!! note "Module repositories"
    The runner must be able to clone each repository that holds modules that your Terragrunt configuration uses.

    - On GitHub, the runner clones with the token of the Stategraph GitHub App, so install the app on each module repository.
    - On GitLab, make sure that the pipeline can read each module project.

## Automatic discovery for large monorepos

In a repository with many Terragrunt modules, a `dirs` entry for each module is tedious and error-prone. The Orchestration config builder generates the configuration for you. For setup and usage, see [Terragrunt config builder](/docs/orchestration/workflows/advanced/terragrunt-config-builder).

### Quick example

In place of hundreds of `dirs` entries, turn on discovery:

```yaml
engine:
  name: terragrunt
  version: 0.69.3

config_builder:
  enabled: true
  script: terragrunt-config-builder
```

The builder then:

- Finds each `terragrunt.hcl` file in the repository
- Parses `dependency` and `include` blocks
- Generates `when_modified` patterns for each module
- Creates `depends_on` relationships for layered execution
- Reads `extra_terrateam_dependencies` (or `extra_atlantis_dependencies`) for custom file tracking

## Best practices

- Keep Terragrunt configurations modular and reusable, to reduce duplication.
- Use one naming convention for `terragrunt.hcl` files and directories.

## Next Steps

- [Terragrunt config builder](/docs/orchestration/workflows/advanced/terragrunt-config-builder): automatic discovery with dependency tracking
- [Layered runs](/docs/orchestration/workflows/advanced/layered-runs): ordering dependent directories
- [engine reference](/docs/reference/orchestration/configuration/engine): the `terragrunt` engine keys, including `tf_cmd` and `tf_version`
