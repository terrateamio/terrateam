---
title: Tags and Tag Queries
description: Group directories and workspaces with tags, then target them with tag queries in workflows, access control, apply requirements, and commands.
order: 9
---


Tags label the directories and workspaces in your repository, and tag queries select them. A tag can name an environment, an application, a region, or any other group. Stategraph Orchestration uses tag queries to select the workflow of a directory, the users who can operate on it, its apply requirements, and the directories that a pull request command targets.

## Defining tags

You define tags in two places:

1. The top-level `tags` key, for tags from the pull request.
2. The `dirs` section, for tags on directories and workspaces.

### Top-level tags

The top-level [`tags`](/docs/reference/orchestration/configuration/tags) key defines tags from the branches of a pull request. These tags are dynamic: their value depends on the pull request. Use them to build workflows that adapt to the destination branch.

```yaml
tags:
  dest_branch:
    main: '^main$'
    staging: '^staging$'
    dev: '^dev$'
```

This defines a `dest_branch` tag with three values: `main`, `staging`, and `dev`. Each value has a Lua pattern that Orchestration matches against the destination branch name. A pull request into `main` gets the `dest_branch:main` tag. The `tags.branch` key defines `branch:<value>` tags from the source branch name in the same way.

### Directory-level tags

The [`dirs`](/docs/reference/orchestration/configuration/dirs) section assigns tags to directories. These tags are static: they belong to the directory, whatever pull request is open.

```yaml
dirs:
  dev:
    tags: [dev]
  staging:
    tags: [staging]
  prod:
    tags: [prod]
```

The `dev`, `staging`, and `prod` directories get the matching tag. Workspaces can have their own tags under `dirs.<directory>.workspaces.<workspace>.tags`.

### Implicit tags

Each directory gets a `dir:<path>` tag, and each workspace a `workspace:<name>` tag, with no configuration. For example, `dir:prod/network` and `workspace:default`.

## Writing tag queries

A tag query is a boolean expression over tags.

### Syntax

| Operator | Matches | Example |
|----------|---------|---------|
| `and` | All listed tags are present. This is the default when no operator is written. | `prod and api`: directories with both the `prod` and `api` tags. |
| `or` | At least one listed tag is present. | `staging or dev`: directories with the `staging` or the `dev` tag. `dir:app or dir:database`: the `app` directory or the `database` directory. |
| `not` | The tag is absent. | `not deprecated`: directories without the `deprecated` tag. |
| `in` | `<path> in dir` matches directories whose path contains `<path>` as whole path components, like the glob `**/<path>/**`. Glob characters in `<path>` match only themselves. Only `dir` is accepted on the right-hand side. | `app in dir`: directories with a path component named `app`, such as `services/app/prod`. |
| Parentheses | Groups expressions and sets their order. | `(web or api) and prod`: directories with the `web` or `api` tag that also have `prod`. |

`and` is the default, so a space between two terms means that both must be true of the same directory. A directory is only one directory, so `dir:app dir:database` matches nothing. To select several directories, join them with `or`.

`and` binds more tightly than `or`, written or implied: `prod api or dev` means `(prod and api) or dev`. In a query that mixes `and` and `or`, use parentheses to make the order explicit. In a long list of directories, a missing `or` turns two entries into one `and` that never matches. Those directories are then silently left out of the run.

### Combining top-level and directory-level tags

One query can combine dynamic and static tags:

```yaml
workflows:
  - tag_query: 'dest_branch:main and prod'
    plan:
      - type: init
      - type: plan
    apply:
      - type: init
      - type: apply
```

This workflow runs only when the pull request targets `main` and the directory has the `prod` tag.

## Using tag queries

### Workflows

In the [`workflows`](/docs/reference/orchestration/configuration/workflows) section, `tag_query` selects the directories of a workflow:

```yaml
workflows:
  - tag_query: 'dest_branch:main and prod'
    plan:
      - type: init
      - type: plan
    apply:
      - type: init
      - type: apply
  - tag_query: 'dest_branch:staging and staging'
    plan:
      - type: init
      - type: plan
    apply:
      - type: init
      - type: apply
```

The first workflow covers pull requests into `main` that change `prod` directories. The second covers pull requests into `staging` that change `staging` directories.

!!! note "First match wins"
    When several workflow entries match a directory, Orchestration uses the first one. The same rule applies to [apply requirements](/docs/reference/orchestration/configuration/apply-requirements) and [access control](/docs/reference/orchestration/configuration/access-control) policies.

### Pull request commands

A tag query after `stategraph plan` or `stategraph apply` limits the command to the matching directories:

- `stategraph plan dir:aws and workspace:prod` plans only the `aws` directory in the `prod` workspace.
- `stategraph apply staging` applies only the directories tagged `staging`.

See the [plan](/docs/reference/orchestration/commands/plan) and [apply](/docs/reference/orchestration/commands/apply) command references.

### Other sections

Tag queries also select entries in `apply_requirements.checks`, `access_control.policies`, `stacks.names.<name>.tag_query`, and the `depends_on` key of `when_modified`.

## Best practices

- Use consistent tag names that match your environments and naming conventions.
- Keep queries short and specific to the directories that you mean.

## Next steps

- [tags reference](/docs/reference/orchestration/configuration/tags)
- [tag queries reference](/docs/reference/orchestration/configuration/tag-queries)
- [Multiple environments](/docs/orchestration/workflows/advanced/multi-environment)
- [Gitflow](/docs/orchestration/workflows/advanced/gitflow)
