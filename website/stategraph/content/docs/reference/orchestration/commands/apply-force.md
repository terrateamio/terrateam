---
title: stategraph apply-force
description: Run an apply from a pull request comment even when the apply requirements are not met, without Gatekeeper gates, as a trusted user.
order: 5
---


`stategraph apply-force` is a pull request comment, not a terminal command: it runs an apply even when the pull request does not meet its [apply requirements](/docs/reference/orchestration/configuration/apply-requirements). It also bypasses [Gatekeeper](/docs/orchestration/governance/gatekeeper) gates: Orchestration does not check them and requests no gate approval.

With [access control](/docs/reference/orchestration/configuration/access-control), only the users in the `apply_force` list of a policy can run it. By default, the list is empty.

!!! warning "Trusted users only"
    Use `apply-force` only when necessary, and restrict it to trusted users. Every force apply is logged for audit.

## Usage

```text
stategraph apply-force [tag-query]
```

A [tag query](/docs/reference/orchestration/configuration/tag-queries) filters by `dir:<path>`, `workspace:<name>`, or tag name, with `and`, `or`, and `not`.

## Examples

All plans:

```text
stategraph apply-force
```

A specific directory:

```text
stategraph apply-force dir:hotfix
```

Production changes:

```text
stategraph apply-force production
```

A complex query:

```text
stategraph apply-force dir:critical and workspace:prod
```

## Related commands

- [stategraph apply](/docs/reference/orchestration/commands/apply): the standard apply with requirements
- [stategraph gate approve](/docs/reference/orchestration/commands/gate-approve): approve validation gates instead of skipping them
