---
title: Terraform
description: Pin the Terraform CLI version Stategraph Orchestration runs, per directory, per workflow, or for the whole repository, and choose the engine.
order: 1
---

Stategraph Orchestration runs Terraform on your CI runners, at the version that you set per directory, per workflow, or for the whole repository. You can also choose another engine. Module and provider constraints often need a specific Terraform CLI version, and the version can differ between directories.

## Set the Terraform version

Orchestration uses the first of these sources that sets a version:

1. A `.terraform-version` file. Orchestration looks in the directory where Terraform runs, then in each parent directory up to the root of the repository, and uses the nearest file.
2. The `engine` of the matching workflow in `.stategraph/config.yml`
3. The top-level `engine.version` in `.stategraph/config.yml`

### `.terraform-version` files

To pin the version for one directory, add a `.terraform-version` file to it:

```
prod/
  ec2/
    .terraform-version
    main.tf
```

Here, the file sets the Terraform version for `prod/ec2/`. A file in the root of the repository sets the default for each directory without a nearer file.

### Workflow configuration

The [workflows](/docs/reference/orchestration/configuration/workflows) key sets custom workflows for the directories that [tag queries](/docs/orchestration/workflows/advanced/tag-system) match. Each workflow can have its own engine and version.

```yaml
dirs:
  ec2/us-east-1/production:
    tags: [ec2, us-east-1, production]
  ec2/us-west-1/production:
    tags: [ec2, us-west-1, production]
workflows:
  - tag_query: ec2 us-east-1 production
    engine:
      name: terraform
      version: 1.5.7
  - tag_query: ec2 us-west-1 production
    engine:
      name: terraform
      version: 1.5.5
```

Directories with the tags `ec2`, `us-east-1`, and `production` run Terraform 1.5.7. Directories with `us-west-1` in place of `us-east-1` run Terraform 1.5.5.

### Default version

Set a default version with the top-level `engine.version`, so that runs stay consistent and Terraform does not upgrade unexpectedly. Use directory or workflow versions only when a module or provider needs them.

```yaml
engine:
  name: terraform
  version: 1.5.7
```

## Choose the engine

Terraform is the default engine. `engine.name` also accepts `tofu` (OpenTofu), `stategraph` (the `stategraph` CLI), `terragrunt`, `pulumi`, `cdktf`, and `custom` (your own command for each step). See the [engine reference](/docs/reference/orchestration/configuration/engine) for the keys of each engine.

With `stategraph`, plans and applies run through Infrastructure as a Database, not against a state file. A plan covers only the resources that the change touches, and Stategraph detects conflicts per resource, not per state file.

```yaml
engine:
  name: stategraph
```

For setup, secrets, and limits, see [Use with Orchestration](/docs/infrastructure-as-a-database/orchestration).

## Next Steps

- [OpenTofu](/docs/orchestration/iac-tools/opentofu): run the community Terraform-compatible engine
- [engine reference](/docs/reference/orchestration/configuration/engine): every engine and its keys
- [Use with Orchestration](/docs/infrastructure-as-a-database/orchestration): scoped plans and per-resource locks in pull requests
