---
title: stategraph plan
description: Run the plan workflow from a pull request comment, for every changed directory, or only for the directories that match a tag query.
order: 2
---


`stategraph plan` is a pull request comment, not a terminal command: it runs a plan to preview infrastructure changes before an apply.

- The plan runs the [workflow](/docs/reference/orchestration/configuration/workflows) in `.stategraph/config.yml`.
- Orchestration stores the plan files for the later apply. [storage](/docs/reference/orchestration/configuration/storage) sets where.
- With [access control](/docs/reference/orchestration/configuration/access-control), the `plan` list of a policy sets who can run it. By default, everyone can.

## Usage

```text
stategraph plan [tag-query]
```

Without a tag query, the command plans every changed directory. A [tag query](/docs/reference/orchestration/configuration/tag-queries) filters by `dir:<path>`, `workspace:<name>`, or tag name, with `and`, `or`, and `not`.

When the tag query has only `dir:` and `workspace:` tags and no `not`, Orchestration plans the named directories again, even when their previous plan found no changes.

## Examples

All changes:

```text
stategraph plan
```

A specific directory:

```text
stategraph plan dir:staging
```

A specific workspace:

```text
stategraph plan workspace:production
```

Multiple directories:

```text
stategraph plan dir:app or dir:database
```

A complex tag query:

```text
stategraph plan production and dir:us-east-1
```

## Related commands

- [stategraph apply](/docs/reference/orchestration/commands/apply): apply the planned changes
