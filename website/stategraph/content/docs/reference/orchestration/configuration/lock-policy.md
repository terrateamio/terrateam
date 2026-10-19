---
title: lock_policy
description: Reference for the lock_policy key in .stategraph/config.yml. Decide when a directory and workspace acquire a lock across the repository.
order: 17
---


`lock_policy` sets when Stategraph Orchestration locks a directory and workspace. The top-level key is the default for every directory, including directories that match no [workflow](/docs/reference/orchestration/configuration/workflows). A `lock_policy` on a workflow entry overrides it for the directories that match that workflow.

## Default Configuration

```yaml
lock_policy: strict
```

## Keys

| Key | Type | Description |
| --- | --- | --- |
| `lock_policy` | string | `strict`: lock when the directory is merged or applied. `apply`: lock only when it is applied. `merge`: lock only when it is merged. `none`: never lock. Default is `strict`. |

Any value other than `strict` is less safe, but can be useful in the right situation. For each policy, and for when a lock is acquired and released, see [Lock management](/docs/orchestration/workflows/advanced/lock-management).

## Examples

### Setting the Policy for the Whole Repository

```yaml
lock_policy: apply
```

Each directory gets a lock only when it is applied.

### Overriding the Policy for Some Directories

```yaml
lock_policy: apply

workflows:
  - tag_query: dir:production
    lock_policy: strict
```

The `production` directory uses `strict`. All other directories use `apply` from the top-level key.

## Related

- [Lock management](/docs/orchestration/workflows/advanced/lock-management)
- [workflows](/docs/reference/orchestration/configuration/workflows)
- [stategraph unlock](/docs/reference/orchestration/commands/unlock)
