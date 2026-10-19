---
title: Terragrunt Config Builder
description: Discover every Terragrunt module in a monorepo with the bundled config builder script and generate depends_on ordering from dependency blocks.
order: 4
---


The Terragrunt config builder finds every `terragrunt.hcl` in a monorepo and generates the Stategraph Orchestration configuration, with dependency tracking. Without it, you list each module in `.stategraph/config.yml` by hand, which is tedious and error-prone in a monorepo with hundreds of modules. The config builder follows the same approach as [terragrunt-atlantis-config](https://github.com/transcend-io/terragrunt-atlantis-config) for Atlantis.

## When to use it

- Large monorepos with many Terragrunt modules.
- Repositories that use Terragrunt `dependency` blocks for module relationships.
- Teams that migrate from Atlantis with terragrunt-atlantis-config.
- Any repository where you do not want to maintain hundreds of `dirs` entries by hand.

With a few modules, manual configuration can be simpler.

## How it works

The config builder runs on your runner, with full access to the repository checkout. It reads the current configuration as JSON on stdin, and writes the modified configuration as JSON to stdout. The config builder:

1. Finds every `terragrunt.hcl` file in the repository.
2. Parses each file.
3. Generates `when_modified` file patterns for each module.
4. Builds the dependency chain as [layered runs](/docs/orchestration/workflows/advanced/layered-runs).

It reads these parts of each `terragrunt.hcl`:

- `dependency` blocks: one `depends_on` relationship each.
- `dependencies` blocks: several dependencies.
- `include` blocks: parent configuration files.
- Local `terraform.source` references. It ignores remote sources.
- `locals.extra_atlantis_dependencies`: custom dependencies.

### What gets generated

For each Terragrunt module, the config builder creates a `dirs` entry with:

- `tags`: `['terragrunt']`, to filter the modules.
- `when_modified.file_patterns`: the files whose change triggers the module.
- `when_modified.depends_on`: the direct dependencies of the module, for layered runs.

## Quick start

1. Enable the config builder in `.stategraph/config.yml`. The runner includes the `terragrunt-config-builder` script, so you reference it by name in `config_builder.script`:

```yaml
engine:
  name: terragrunt
  version: 0.69.3

config_builder:
  enabled: true
  script: terragrunt-config-builder

when_modified:
  autoplan: true
```

2. Commit and push the change to a branch.
3. Open a pull request.
4. Comment `stategraph repo-config` on the pull request to see the generated configuration.
5. Autoplan runs for every module that the config builder finds.

## Configuration

### Minimal

```yaml
engine:
  name: terragrunt

config_builder:
  enabled: true
  script: terragrunt-config-builder
```

### With a Terragrunt version

```yaml
engine:
  name: terragrunt
  version: 0.69.3

config_builder:
  enabled: true
  script: terragrunt-config-builder
```

### With OpenTofu underneath

```yaml
engine:
  name: terragrunt
  version: 0.69.3
  tf_cmd: tofu
  tf_version: "1.9.0"

config_builder:
  enabled: true
  script: terragrunt-config-builder
```

See the [engine reference](/docs/reference/orchestration/configuration/engine) for every Terragrunt engine key.

## Example output

### Repository structure

```text
non-prod/
├── us-east-1/
│   ├── qa/
│   │   ├── mysql/
│   │   │   └── terragrunt.hcl
│   │   └── webserver-cluster/
│   │       └── terragrunt.hcl  # depends on mysql
│   └── stage/
│       ├── mysql/
│       │   └── terragrunt.hcl
│       └── webserver-cluster/
│           └── terragrunt.hcl  # depends on mysql
prod/
├── us-east-1/
│   └── prod/
│       ├── mysql/
│       │   └── terragrunt.hcl
│       └── webserver-cluster/
│           └── terragrunt.hcl  # depends on mysql
repo.hcl
aws.hcl
```

### Generated configuration

`stategraph repo-config` shows entries like these. The `stage` and `prod` modules have the same shape.

```json
{
  "version": "1",
  "dirs": {
    "non-prod/us-east-1/qa/mysql": {
      "tags": ["terragrunt"],
      "when_modified": {
        "file_patterns": [
          "${DIR}/terragrunt.hcl",
          "${DIR}/*.tf",
          "${DIR}/*.tfvars"
        ]
      }
    },
    "non-prod/us-east-1/qa/webserver-cluster": {
      "tags": ["terragrunt"],
      "when_modified": {
        "file_patterns": [
          "${DIR}/terragrunt.hcl",
          "${DIR}/*.tf",
          "${DIR}/*.tfvars",
          "non-prod/us-east-1/qa/mysql/terragrunt.hcl"
        ],
        "depends_on": "dir:non-prod/us-east-1/qa/mysql"
      }
    }
  }
}
```

- The `mysql` modules have no `depends_on`, because they depend on nothing.
- Each `webserver-cluster` module depends on the `mysql` module next to it.
- The file patterns include the `terragrunt.hcl` of the dependency, so a change there also triggers the dependent module.

Directories that Terragrunt generates at run time, for example with `terragrunt stack generate`, do not exist in the checkout yet. Set `create_if_missing: true` on those `dirs` entries. See the [dirs reference](/docs/reference/orchestration/configuration/dirs).

## Next steps

- [Terragrunt integration](/docs/orchestration/iac-tools/terragrunt): basic Terragrunt setup.
- [config_builder reference](/docs/reference/orchestration/configuration/config-builder)
- [Layered runs](/docs/orchestration/workflows/advanced/layered-runs): how `depends_on` orders execution.
- [Dynamic configuration](/docs/orchestration/workflows/advanced/dynamic-configuration): where the config builder sits in the merge order.
