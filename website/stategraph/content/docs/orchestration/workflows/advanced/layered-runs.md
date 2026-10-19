---
title: Layered Runs
description: Order plan and apply across dependent layers of infrastructure with depends_on, so each layer runs only after the layers it depends on have applied.
order: 2
---


Layered runs plan and apply dependent directories in order. Stategraph Orchestration runs each layer only after the layers that it depends on apply successfully. For example, a network must exist before the database in it, and the database must exist before the application that connects to it.

## How it works

The `depends_on` key in the `when_modified` configuration of a directory names the directories that must apply first. See the [when_modified reference](/docs/reference/orchestration/configuration/when-modified).

!!! tip "The DIR variable"
    `${DIR}` in `file_patterns` expands to the directory that the `dirs` entry matches. For the key `envs/asia/database`, `${DIR}` is `envs/asia/database`. See the [dirs reference](/docs/reference/orchestration/configuration/dirs).

Add this to `.stategraph/config.yml`:

```yaml
dirs:
  network:
    when_modified:
      file_patterns: ["${DIR}/*.tf"]
  database:
    when_modified:
      depends_on: 'dir:network'
      file_patterns: ["${DIR}/*.tf"]
  application:
    when_modified:
      depends_on: 'dir:database'
      file_patterns: ["${DIR}/*.tf"]
```

With this configuration:

1. If `network` changes, Orchestration plans and applies it first.
2. After the `network` apply succeeds, Orchestration plans and applies `database`.
3. After the `database` apply succeeds, Orchestration plans and applies `application`.

If a layer has no changes, its plan comment says so and tells you when the next layer follows.

## Dependency expressions

`depends_on` is a [tag query](/docs/reference/orchestration/configuration/tag-queries), so it accepts logical operators and two directory prefixes.

### Logical operators

Combine dependencies with `or` and `and`. A change in any directory that the query names triggers the dependent layer.

```yaml
dirs:
  application:
    when_modified:
      depends_on: 'dir:network or dir:database'
```

Here a change to `network` or to `database` triggers `application`. Set `depends_on` under `dirs.<directory>.when_modified`. Under the top-level `when_modified`, it applies to every directory, the dependencies included.

### Directory references

`dir:` names an absolute path from the repository root. Use it when the directory layout is fixed.

```yaml
dirs:
  database:
    when_modified:
      depends_on: 'dir:network'
```

`relative_dir:` names a path relative to the current directory. Use it when the same rule applies to many environments, or when the layout can move.

```yaml
dirs:
  envs/prod/database:
    when_modified:
      depends_on: 'relative_dir:../network'
```

### Pruning layers without changes

By default, when a dependency changes, the dependent layer joins the run even if it has no changes of its own. To keep a layer in the order without running it on each upstream change, use the object form of `depends_on` and set `prune_on_no_change: true`. The layer then runs only when it has changes of its own, and it still orders the layers that depend on it.

```yaml
dirs:
  database:
    when_modified:
      depends_on:
        tag_query: 'dir:network'
        prune_on_no_change: true
      file_patterns: ["${DIR}/*.tf"]
```

Here `database` is ordered after `network`, but a change to `network` alone does not plan or apply `database`.

### Pruning layers when outputs do not change

`prune_on_no_change` asks if the dependent layer changed. An `outputs:` dependency asks a different question: did the apply of the layer below change a value that the layer above reads? A layer that depends on an output runs only when that output changed.

```yaml
dirs:
  network:
    when_modified:
      file_patterns: ["${DIR}/*.tf"]
  database:
    when_modified:
      depends_on: 'vpc_id in outputs:network'
      file_patterns: ["${DIR}/*.tf"]
  application:
    when_modified:
      depends_on: 'endpoint in outputs:database'
      file_patterns: ["${DIR}/*.tf"]
```

A change to a tag of the VPC changes no output. The apply of `network` completes, and Orchestration removes `database` from the run. `application` depends on an output of `database`, and `database` did not run, so Orchestration removes `application` too. The full branch above the change goes away, and the pull request is complete.

If you change the CIDR of the VPC, `vpc_id` changes, so `database` plans and applies as usual. The `endpoint` output of `database` then decides, in the same way, if `application` runs.

The comparison is against the most recent successful apply of that layer in a different pull request. So it tells you if this pull request changed the value, not only if the layer applied. For the path syntax, the engines that record outputs, and the cases that always run, see [Depending on outputs](/docs/reference/orchestration/configuration/when-modified#depending-on-outputs).

To bring back a pruned layer, comment an explicit plan that names it:

```text
stategraph plan dir:database
```

Add `workspace:<name>` to name one workspace of the directory. The layer plans, and after the plan you can apply it. Its outputs then decide again for its dependents, so explicit plans walk the branch one layer at a time.

### Layers and stacks

With a [stacks](/docs/orchestration/workflows/advanced/stacks) section, a `depends_on` can name only directories in the same stack, or in a stack that shares a nested stack with it. A directory in an unrelated stack is a configuration error. To order two unrelated stacks, use the stack rules `plan_after` and `apply_after`.

## Use cases

### Sequential infrastructure deployment

Layers that depend on each other must deploy in order: when you rebuild from scratch, for example in disaster recovery, and when you change one layer.

```yaml
dirs:
  network:
    when_modified:
      file_patterns: ["${DIR}/*.tf"]
  database:
    when_modified:
      depends_on: 'dir:network'
      file_patterns: ["${DIR}/*.tf"]
  application:
    when_modified:
      depends_on: 'dir:database'
      file_patterns: ["${DIR}/*.tf"]
```

### Multiple layers with shared dependencies

`app1` and `app2` both depend on a shared `database`, which depends on `network`. A change to `network` reaches `database`, then both applications. `shared_resources` depends on either of the two lower layers.

```yaml
dirs:
  network:
    when_modified:
      file_patterns: ["${DIR}/*.tf"]
  database:
    when_modified:
      depends_on: 'dir:network'
      file_patterns: ["${DIR}/*.tf"]
  app1:
    when_modified:
      depends_on: 'dir:database'
      file_patterns: ["${DIR}/*.tf"]
  app2:
    when_modified:
      depends_on: 'dir:database'
      file_patterns: ["${DIR}/*.tf"]
  shared_resources:
    when_modified:
      depends_on: 'dir:network or dir:database'
      file_patterns: ["${DIR}/*.tf"]
```

### One configuration for every environment

When environments share a layout, define each layer once with a glob and `relative_dir:`. In this repository, four environments each hold some of the services `application`, `database`, `networking`, and `block_storage`.

```text
.
└── envs
    ├── asia
    │   ├── application
    │   │   └── main.tf
    │   ├── database
    │   │   └── main.tf
    │   └── networking
    │       └── main.tf
    ├── europe
    │   ├── application
    │   │   └── main.tf
    │   ├── block_storage
    │   │   └── main.tf
    │   ├── database
    │   │   └── main.tf
    │   └── networking
    │       └── main.tf
    ├── us-east
    │   ├── application
    │   │   └── main.tf
    │   ├── database
    │   │   └── main.tf
    │   └── networking
    │       └── main.tf
    └── us-west
        ├── application
        │   └── main.tf
        ├── block_storage
        │   └── main.tf
        ├── database
        │   └── main.tf
        └── networking
            └── main.tf
```

The layers, from bottom to top:

1. `networking`
2. `database` and `block_storage`
3. `application`

```yaml
dirs:
  'envs/*/database':
    when_modified:
      depends_on: 'relative_dir:../networking'
  'envs/*/block_storage':
    when_modified:
      depends_on: 'relative_dir:../networking'
  'envs/*/application':
    when_modified:
      depends_on: 'relative_dir:../database or relative_dir:../block_storage'
```

If `envs/asia/database` changes, `envs/asia/application` runs after it. If `envs/us-west/networking` changes, `envs/us-west/database` and `envs/us-west/block_storage` run next, then `envs/us-west/application`.

Only two environments have `block_storage`. The rule applies only to the directories that exist.

## Best practices

- Make `depends_on` match real dependencies. Orchestration cannot order circular dependencies.
- Combine `depends_on` with tag queries to trigger only the layers that a change needs.
- Split infrastructure into layers that you can manage separately. Small layers keep the order simple and the runs short.

## Next steps

- [Stacks](/docs/orchestration/workflows/advanced/stacks): group directories and order whole groups.
- [Terragrunt config builder](/docs/orchestration/workflows/advanced/terragrunt-config-builder): generate `depends_on` from Terragrunt dependency blocks.
- [when_modified reference](/docs/reference/orchestration/configuration/when-modified)
