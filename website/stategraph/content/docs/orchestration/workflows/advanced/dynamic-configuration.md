---
title: Dynamic Configuration
description: Generate the repository configuration at runtime with config_builder, a script that reads the merged configuration and writes the final one.
order: 3
---


Stategraph Orchestration can generate the repository configuration at the start of each operation with [`config_builder`](/docs/reference/orchestration/configuration/config-builder), a script that you write. Use it when a static `.stategraph/config.yml` cannot express your setup: for example, when the configuration depends on the repository layout, on an API call, or on a format of your own.

## How it works

Orchestration runs the script on the runner, in a checkout of the repository. The script reads the configuration assembled so far and writes the final configuration. Orchestration merges that output with the other configuration sources to make the repository configuration for the run.

!!! warning "Security implications"
    A config builder script runs with access to the repository contents, the runner environment, and any configured secrets. Only trusted users should change or approve these scripts. Review every script for unintended behavior before you enable it.

To restrict who can change a script that the config builder calls, use `access_control.files`:

```yaml
access_control:
  files:
    bin/script-that-handles-sensitive-things: ['role:admin']
```

Orchestration also applies these rules to a configuration from a config builder:

1. `access_control`, `apply_requirements`, and `destination_branches` always come from the default branch configuration, which Orchestration builds without the config builder.
2. Explicit configuration in the feature branch's `.stategraph/config.yml` overrides the config builder output. If the file explicitly enables `indexer`, the config builder cannot disable it.
3. Overrides in the centralized configuration always win.
4. The `terrateam_config_update` access control rule applies to `.stategraph/config.yml`.

Put as much of the config builder logic as possible in the `script` value, or make the script verify the contents of each program that it calls. The script then stays under the same access control as the configuration file.

### Configuration merge order

Orchestration assembles the final configuration in this order. Each step is merged over the one before it.

1. Centralized defaults
2. Centralized overrides
3. Repository defaults
4. Repository overrides
5. Repository forced configuration
6. Default branch configuration
7. Feature branch configuration
8. Config builder output

Some sections, such as access control, always come from the default branch configuration. See [Centralized configuration](/docs/orchestration/governance/centralized-config) for the first five steps. To see the result, comment [`stategraph repo-config`](/docs/reference/orchestration/commands/repo-config) on a pull request. Orchestration replies with the full merged configuration.

### Configuration

```yaml
config_builder:
  enabled: true
  script: |
    #! /usr/bin/env bash
    # Insert your script logic here to dynamically generate configuration
```

- Input: the script reads the current repository configuration as JSON on `stdin`. Directory globs are already expanded, and implicit tags are already present.
- Output: the script writes the repository configuration as JSON to `stdout`. The output must be a valid repository configuration.
- Interpreter: a `script` that does not begin with a shebang (`#!`) runs as a bash script. Orchestration adds the shebang before it runs the script.
- Errors: a failed script fails the run. Orchestration reports a script failure or invalid output in a comment on the pull request.

## Use cases

Static configuration is easier to maintain and to understand. These cases are not possible without `config_builder`.

### Fine-grained access control

The `terrateam_config_update` rule covers the whole configuration file. To let a different group of users manage part of the configuration, move that part to a separate file. Merge it with a config builder script, and protect the file with `access_control.files`. You delegate that part and keep control of the rest.

### Custom tags

Directory names can encode environment, region, and service, such as `prod/us-east/database`. A config builder script can parse the paths and add tags, so that one tag query plans all of `us-east`. Static configuration cannot do this.

### Bespoke configuration syntax

A config builder script can translate a configuration format of your own into the repository configuration. The bundled `terrateam-aux-repo-config` script is an example: it reads layer dependencies from a separate YAML file. See [The aux config builder](#the-aux-config-builder).

### Automatic Terragrunt discovery

In a Terragrunt monorepo with hundreds of modules, you cannot practically configure each module by hand. The bundled [Terragrunt config builder](/docs/orchestration/workflows/advanced/terragrunt-config-builder) finds every `terragrunt.hcl` and parses `dependency`, `include`, and local `terraform.source` references. It generates `when_modified` patterns and `depends_on` relationships for each module.

### Experimentation

A config builder script is a good place to try a configuration idea before you ask for it as a built-in feature.

## The aux config builder

The runner includes a config builder script named `terrateam-aux-repo-config`. It reads `.terrateam/aux.yml` and translates a list of layer dependencies into `depends_on` tag queries. The script reads only that path, so the file stays in the `.terrateam` directory even when your repository configuration is `.stategraph/config.yml`.

For this repository layout:

```text
.
└── projects
    ├── proj1
    │   ├── base
    │   │   └── main.tf
    │   ├── database1
    │   │   └── main.tf
    │   ├── database2
    │   │   └── main.tf
    │   └── webservice
    │       └── main.tf
    ├── proj2
    │   ├── base
    │   │   └── main.tf
    │   ├── database1
    │   │   └── main.tf
    │   ├── database2
    │   │   └── main.tf
    │   └── webservice
    │       └── main.tf
    └── proj3
        ├── base
        │   └── main.tf
        ├── database1
        │   └── main.tf
        ├── database2
        │   └── main.tf
        └── webservice
            └── main.tf
```

Define the layers in `.terrateam/aux.yml`:

```yaml
dirs:
  projects/proj1/database1:
    deps:
      - projects/proj1/base
  projects/proj1/database2:
    deps:
      - projects/proj1/base
  projects/proj2/database1:
    deps:
      - projects/proj2/base
  projects/proj2/database2:
    deps:
      - projects/proj2/base
  projects/proj3/database1:
    deps:
      - projects/proj3/base
  projects/proj3/database2:
    deps:
      - projects/proj3/base
  projects/proj1/webservice:
    deps:
      - projects/proj1/database1
      - projects/proj1/database2
  projects/proj2/webservice:
    deps:
      - projects/proj2/database1
      - projects/proj2/database2
  projects/proj3/webservice:
    deps:
      - projects/proj3/database1
      - projects/proj3/database2
```

Enable the script in `.stategraph/config.yml`:

```yaml
config_builder:
  enabled: true
  script: |
    #! /usr/bin/env bash
    terrateam-aux-repo-config
```

## Best practices

- Use `config_builder` only for what static configuration cannot express. Keep everything else in `.stategraph/config.yml` or the centralized configuration. A generated configuration can be hard to reason about, and it can differ from one run to the next.
- Handle errors in the script, especially around external APIs and data sources.

## Next steps

- [config_builder reference](/docs/reference/orchestration/configuration/config-builder)
- [Terragrunt config builder](/docs/orchestration/workflows/advanced/terragrunt-config-builder)
- [Tree builder](/docs/orchestration/workflows/advanced/tree-builder-setup): customize file discovery before the config builder runs.
