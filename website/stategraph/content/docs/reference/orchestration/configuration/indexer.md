---
title: indexer
description: Reference for the indexer key in .stategraph/config.yml. Generate directory and module configuration by analyzing your Terraform code.
order: 16
---


`indexer` makes Stategraph Orchestration generate parts of the repository configuration from the repository structure and your Terraform code. You write less configuration by hand, and it helps make sure that the correct directories run on plan and apply.

## Default Configuration

```yaml
indexer:
  enabled: false
```

## Keys

| Key | Type | Description |
| --- | --- | --- |
| `enabled` | boolean | Turns on the indexer. Default is `false`. |
| `build_tag` | string | Deprecated and ignored. The runner indexes with the Stategraph CLI built into the action image and does not pull an indexer image. |

## Functionality

The indexer maps the Terraform modules, the directories that reference them, and the symbolic links in the repository. Orchestration uses this map to find the directories that run on plan and apply:

- Modules: when a `module` block references a directory, a change to that module directory does not run the module directory. It runs the directories that reference the module.
- Symlinks: Orchestration treats a symbolic link as the file or directory that it references.

## Usage

- When the indexer is enabled, it runs on a change if no index exists for that commit hash.
- To force a new index, comment `stategraph index` on a pull request.
- To review the configuration that the indexer generated, comment `stategraph repo-config` on the pull request. It shows how Orchestration reads your repository structure and Terraform code.

## Related

- [Modules](/docs/orchestration/configuration/modules)
- [stategraph repo-config](/docs/reference/orchestration/commands/repo-config)
- [tree_builder](/docs/reference/orchestration/configuration/tree-builder)
