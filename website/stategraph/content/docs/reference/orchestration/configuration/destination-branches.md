---
title: destination_branches
description: Reference for the destination_branches key in .stategraph/config.yml. Control which target and source branches trigger operations.
order: 9
---


`destination_branches` sets which destination branches, and which source branches, trigger Stategraph Orchestration operations on a pull request. By default, only a pull request to the default branch of the repository (usually `main` or `master`) triggers operations.

## Default Configuration

```yaml
destination_branches: []
```

## Keys

`destination_branches` is a list. Each entry is a branch name, or an object with these keys:

| Key | Type | Description |
| --- | --- | --- |
| `branch` | string | The branch that the pull request merges into. |
| `source_branches` | array | The branches that can merge into `branch`. Default is `['*']`. |

If no entry matches the pull request, Orchestration does not plan or apply it. After a `stategraph plan` comment, Orchestration comments that the branches do not match.

Orchestration reads `destination_branches` from the default branch while the key is in [`default_branch_overrides`](/docs/reference/orchestration/configuration/default-branch-overrides), as it is by default.

### Branch

A branch name as a string is the same as an object with the `branch` key. These two configurations are equal:

```yaml
destination_branches:
  - main
```

```yaml
destination_branches:
  - branch: main
```

### Source Branches

`source_branches` limits which source branches can merge into the destination branch. To permit any source branch into `main`:

```yaml
destination_branches:
  - branch: main
    source_branches: ['*']
```

## Example

```yaml
destination_branches:
  - main
```

With this configuration, a pull request from `hotfix/revert-ami` to `main` triggers operations:

- `main` matches the `branch` attribute.
- `hotfix/revert-ami` matches the default `source_branches`, `['*']`.

## Globs

The `*` wildcard matches more than one branch, in branch names and in source branches. To permit any branch that starts with `feature/` into `develop`:

```yaml
destination_branches:
  - branch: develop
    source_branches: ['feature/*']
```

## Not Patterns

A `!` before a source branch pattern excludes the branches that match it. To permit any branch into `main`, except the branches that start with `hotfix/`:

```yaml
destination_branches:
  - branch: main
    source_branches: ['*', '!hotfix/*']
```

Review globs and not patterns carefully. They can match more or fewer branches than you expect.

## Related

- [Gitflow](/docs/orchestration/workflows/advanced/gitflow)
- [Multi-environment](/docs/orchestration/workflows/advanced/multi-environment)
- [tags](/docs/reference/orchestration/configuration/tags)
