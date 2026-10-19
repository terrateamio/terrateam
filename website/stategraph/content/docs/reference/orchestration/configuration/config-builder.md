---
title: config_builder
description: Reference for the config_builder key in .stategraph/config.yml. Generate the repository configuration at runtime with a custom script.
order: 5
---


`config_builder` runs a script that generates the Stategraph Orchestration configuration at run time. Use it when the configuration depends on external data, or needs logic that a static file cannot express.

## Default Configuration

```yaml
config_builder:
  enabled: false
```

## Keys

| Key | Type | Description |
| --- | --- | --- |
| `enabled` | boolean | Turns on the config builder. Default is `false`. |
| `script` | string | The script that generates the configuration. Required when `enabled` is `true`. |

## Script

- Input: the current configuration, as a JSON string on `stdin`.
- Output: the new repository configuration, as JSON on `stdout`. It must be a valid Orchestration configuration, or the script must exit with an error.
- The script can use conditionals, environment variables, external commands, and external data sources.
- If the script does not start with a shebang (`#!`), Orchestration runs it as a bash script.
- The output does not override `.stategraph/config.yml`, the overrides of a [centralized configuration](/docs/orchestration/governance/centralized-config), or the keys in `default_branch_overrides`. It overrides the centralized defaults, `global_defaults` and `repo_defaults`.

If the script calls external APIs or reads sensitive data, protect the API keys and other credentials that it uses.

## Examples

### Using Python to Generate Dynamic Configuration

```yaml
config_builder:
  enabled: true
  script: |
    #! /usr/bin/env python3
    import sys
    # Generate configuration here
    sys.exit()
```

## Related

- [Dynamic configuration](/docs/orchestration/workflows/advanced/dynamic-configuration)
- [Terragrunt config builder](/docs/orchestration/workflows/advanced/terragrunt-config-builder)
- [tree_builder](/docs/reference/orchestration/configuration/tree-builder)
