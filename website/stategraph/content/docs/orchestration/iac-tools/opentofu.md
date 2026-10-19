---
title: OpenTofu
description: Run OpenTofu as the engine for Stategraph Orchestration plans and applies, globally or per workflow, and switch between OpenTofu and Terraform.
order: 2
---

Stategraph Orchestration runs OpenTofu in place of Terraform for plans and applies, for the whole repository or for one workflow. [OpenTofu](https://opentofu.org) is a Terraform-compatible engine that the community maintains, and a backward-compatible alternative to the Terraform binary. Unlike the Terraform binary, OpenTofu:

- is [open source](https://github.com/opentofu/opentofu) under the Mozilla Public License, which lets you use, modify, and distribute it
- has community support
- has feature development that the community directs

## Configure OpenTofu

The `engine` key sets the tool that Orchestration runs: Terraform, OpenTofu, the `stategraph` CLI, Terragrunt, Pulumi, CDKTF, or a custom command. To use OpenTofu for all operations, set `engine` in `.stategraph/config.yml`:

```yaml
engine:
  name: tofu
  version: 1.6.2
```

To use OpenTofu for one workflow, set `engine` on that workflow entry:

```yaml
workflows:
  - tag_query: prod
    engine:
      name: tofu
      version: 1.6.2
```

Then use Orchestration as usual. Open a pull request with changes to your Terraform code. Orchestration plans with OpenTofu and comments the output on the pull request. After review and approval, comment `stategraph apply` to apply with OpenTofu, and Orchestration comments its output.

## OpenTofu with Infrastructure as a Database

The `stategraph` CLI also runs OpenTofu. It runs `tofu` when it is on the `PATH`, and `terraform` if not. To choose a specific binary, set the `TF_CMD` environment variable.

With the `stategraph` engine, select OpenTofu with `tf_cmd`:

```yaml
engine:
  name: stategraph
  tf_cmd: tofu
  tf_version: '1.8.8'
```

See [Use with Orchestration](/docs/infrastructure-as-a-database/orchestration).

## Migrate from Terraform

OpenTofu is a drop-in replacement for Terraform, compatible with Terraform 1.5.x and most of 1.6.x. Existing code needs no changes. See the [official migration guide](https://opentofu.org/docs/intro/migration/).

- OpenTofu version numbers do not follow Terraform version numbers. Choose an OpenTofu version that is compatible with your code and provider versions.
- To go back to Terraform, set `engine.name` to `terraform`, and set the version that you want.

## Next Steps

- [Terraform](/docs/orchestration/iac-tools/terraform): version precedence and engine choice
- [engine reference](/docs/reference/orchestration/configuration/engine): every engine and its keys
- [Use with Orchestration](/docs/infrastructure-as-a-database/orchestration): scoped plans and per-resource locks in pull requests
