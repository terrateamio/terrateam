---
title: Custom File Discovery with Tree Builder
description: Replace Git file discovery with a tree_builder script that reports which files exist and which changed, for generated Terraform and custom rules.
order: 8
---


The [`tree_builder`](/docs/reference/orchestration/configuration/tree-builder) configuration replaces the Git file tree and diff with a script that you write. The script reports the files that Stategraph Orchestration sees, and a change identifier for each file.

## When to use tree builder

Use tree builder when the Git view of the repository does not match what a change means for your infrastructure:

- Generated infrastructure: Terraform files that templates or code produce.
- Complex dependencies: a change in a shared library should trigger the services that use it.
- Custom change rules: business logic decides what counts as a change.
- Non-standard layouts: infrastructure patterns that ordinary file tracking cannot express.

## How tree builder works

Tree builder sits between the repository and the workflow engine. The steps run in this order:

1. Indexer: finds the directories and the initial file structure.
2. Tree builder: runs your script, which decides which files exist and which changed.
3. Config builder: generates the runtime configuration, which decides how to process those files.
4. Plan and apply: runs the engine against the final file set.

You can change file discovery without changing the configuration logic, and the other way round.

Tree builder runs in separate runs on your CI runner, not in the plan of a pull request. The destination branch and the feature branch each get a file inventory, stored per commit. Later events on the same commit reuse it. See the [tree_builder reference](/docs/reference/orchestration/configuration/tree-builder) for the sequence of runs and their check names.

## Getting started

1. Enable tree builder in `.stategraph/config.yml`:

```yaml
tree_builder:
  enabled: true
  script: "./scripts/discover_files.sh"
```

2. Write the discovery script. It examines the repository checkout, applies your rules to decide the file list and the identifier of each file, and prints a JSON array to stdout:

```json
[
  {
    "path": "environments/prod/main.tf",
    "id": "a1b2c3d4e5f6789"
  },
  {
    "path": "environments/staging/main.tf",
    "id": "f9e8d7c6b5a4321"
  }
]
```

The `id` is an opaque string that identifies the file contents, usually a hash. Orchestration compares the `id` of each path in the source branch with the `id` in the destination branch. If they differ, the file changed. The output is a bare array, not an object with a `files` key. An empty array is valid, and means that there are no files to track.

3. Test the script locally, and make sure that it produces valid JSON:

```bash
./scripts/discover_files.sh | jq '.'
```

4. Push the change and open a pull request. Orchestration now uses your script to find files and changes.

The feature branch and the destination branch must have the same tree builder configuration.

## Security

!!! warning "Security considerations"
    The script runs on your runner with the repository checkout. Validate every input that it reads. Do not run untrusted code. Use safe file operations. Restrict who can change the script with [`access_control`](/docs/reference/orchestration/configuration/access-control), for example with an `access_control.files` rule on the script path.

## Next steps

- [tree_builder reference](/docs/reference/orchestration/configuration/tree-builder)
- [Dynamic configuration](/docs/orchestration/workflows/advanced/dynamic-configuration): the config builder that runs after tree builder.
- [indexer reference](/docs/reference/orchestration/configuration/indexer)
