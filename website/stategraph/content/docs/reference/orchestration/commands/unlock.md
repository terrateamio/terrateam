---
title: stategraph unlock
description: Release the locks of a pull request or of drift detection from a pull request comment, so that other pull requests and drift runs can proceed.
order: 6
---


`stategraph unlock` is a pull request comment, not a terminal command: it releases the directory locks that pull requests or drift detection runs hold, so that other operations can proceed.

With [access control](/docs/reference/orchestration/configuration/access-control), the `unlock` list sets who can run it. By default, everyone can.

!!! warning "Unlocking can disrupt active operations"
    Restrict unlock to trusted users.

## Usage

```text
stategraph unlock
stategraph unlock <pull-request-number> [pull-request-number...]
stategraph unlock drift
```

## Examples

Release every lock that the current pull request owns:

```text
stategraph unlock
```

Release every lock that pull request 123 owns. Give the number alone, without `#` on GitHub or `!` on GitLab:

```text
stategraph unlock 123
```

Release the locks of several pull requests, for example to clean up locks left by closed or abandoned pull requests:

```text
stategraph unlock 123 456 789
```

Release the locks of [drift detection](/docs/reference/orchestration/configuration/drift) runs. You can combine `drift` with pull request numbers in one command.

```text
stategraph unlock drift
```

## Related

- [Lock management](/docs/orchestration/workflows/advanced/lock-management): lock behavior and configuration
- [stategraph apply](/docs/reference/orchestration/commands/apply): acquires locks on the applied directories and workspaces
- [lock_policy](/docs/reference/orchestration/configuration/lock-policy): controls when locks are acquired
