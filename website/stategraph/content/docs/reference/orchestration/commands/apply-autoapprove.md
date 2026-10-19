---
title: stategraph apply-autoapprove
description: A reserved pull request comment to plan and apply in one step with no review between them, which Orchestration does not run.
order: 4
---


`stategraph apply-autoapprove` is a reserved pull request comment, not a terminal command, to run plan and apply in one operation, with no manual review between them.

!!! warning "Not available"
    Orchestration does not run this command. To apply, run [`stategraph plan`](/docs/reference/orchestration/commands/plan), and then [`stategraph apply`](/docs/reference/orchestration/commands/apply).

The reserved command has two phases:

1. Plan: runs init and plan, and generates the plan output.
2. Apply: applies the plan immediately, with no review and no approval.

!!! warning "Applies without review"
    This command applies changes immediately, with no review step. Restrict it to the environments and users where an unreviewed apply is acceptable.

## Usage

```text
stategraph apply-autoapprove [tag-query]
```

A [tag query](/docs/reference/orchestration/configuration/tag-queries) filters by `dir:<path>`, `workspace:<name>`, or tag name, with `and`, `or`, and `not`.

## Examples

All changes:

```text
stategraph apply-autoapprove
```

The development environment:

```text
stategraph apply-autoapprove dev
```

A specific directory:

```text
stategraph apply-autoapprove dir:staging
```

A complex query:

```text
stategraph apply-autoapprove non-prod and dir:config
```

## Related commands

- [stategraph plan](/docs/reference/orchestration/commands/plan): preview changes first
- [stategraph apply](/docs/reference/orchestration/commands/apply): the standard apply with review
- [stategraph apply-force](/docs/reference/orchestration/commands/apply-force): apply without meeting the requirements
