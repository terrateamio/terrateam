---
title: definitions
description: Reference for the definitions key in .stategraph/config.yml. Hold YAML anchors that other sections reuse, with the merge rules that apply.
order: 8
---


`definitions` holds YAML anchors that you reuse in other parts of the Stategraph Orchestration configuration. You define a value once, reuse it in many places, and change it in one place. This keeps similar configurations consistent, and the file smaller and simpler.

Orchestration does not interpret the contents of `definitions`. It is a free-form object that only holds anchors. Orchestration checks every other top-level key against the configuration schema, so a value from an anchor must be valid where you use it.

## Syntax

```yaml
definitions:
  # Define anchors here using &anchor_name
  std_plan: &std_plan
    - type: init
    - type: plan

# Reference anchors elsewhere using *anchor_name
workflows:
  - tag_query: ""
    plan: *std_plan
```

## Rules

Orchestration resolves anchors, aliases, and the `<<` merge key when it parses the file, not at run time.

- `*anchor` inserts the anchored value: a scalar, a list, or a map.
- `<<: *anchor` merges the keys of an anchored map into the current map. A key in the current map overrides a merged key of the same name.
- To merge more than one map, use a list: `<<: [*first, *second]`. Two `<<:` keys in the same map are a parse error.
- Merging is shallow. Nested maps do not merge.
- An alias cannot address a nested value. `*anchor.key` is a parse error. Anchor the nested value on its own.
- A list alias inside a list makes a nested list. Use the alias as the full value (`plan: *std_plan`), or anchor each entry.
- Define an anchor before its first reference.
- Anchor definitions cannot use environment variables or dynamic values.
- Circular references are not supported.

## Examples

### Reusable Engine Configuration

```yaml
definitions:
  default_engine: &default_engine
    name: terraform
    version: "1.5.0"

workflows:
  - tag_query: "dev"
    engine: *default_engine

  - tag_query: "staging"
    engine:
      <<: *default_engine
      version: "1.5.7"
```

### Standard Workflow Steps

```yaml
definitions:
  standard_plan: &standard_plan
    - type: init
    - type: run
      cmd: ["terraform", "fmt", "-check"]
    - type: run
      cmd: ["terraform", "validate"]
    - type: plan
    - type: checkov

workflows:
  - tag_query: "dev"
    plan: *standard_plan
  - tag_query: "production"
    plan: *standard_plan
```

To make different step lists from the same parts, anchor each step:

```yaml
definitions:
  step_init: &step_init
    type: init
  step_plan: &step_plan
    type: plan
  step_checkov: &step_checkov
    type: checkov

workflows:
  - tag_query: "dev"
    plan:
      - *step_init
      - *step_plan
  - tag_query: "production"
    plan:
      - *step_init
      - *step_plan
      - *step_checkov
```

### Common Access Control Policies

```yaml
definitions:
  dev_access: &dev_access
    plan: ["*"]
    apply: ["team:developers", "team:platform"]

  prod_access: &prod_access
    plan: ["*"]
    apply: ["team:platform"]
    apply_force: ["team:sre"]

access_control:
  enabled: true
  policies:
    - tag_query: "dev or staging"
      <<: *dev_access

    - tag_query: "production"
      <<: *prod_access
```

### Environment-Specific Settings

This example anchors one map of variables for each environment. The runner does not apply `env` on `init` and `plan` steps, so these variables do not reach the engine.

```yaml
definitions:
  aws_dev: &aws_dev
    AWS_REGION: us-east-1
    AWS_ROLE_ARN: arn:aws:iam::123456789012:role/stategraph-dev

  aws_prod: &aws_prod
    AWS_REGION: us-east-1
    AWS_ROLE_ARN: arn:aws:iam::123456789012:role/stategraph-prod

workflows:
  - tag_query: "dev"
    plan:
      - type: init
        env: *aws_dev
      - type: plan
        env: *aws_dev

  - tag_query: "production"
    plan:
      - type: init
        env: *aws_prod
      - type: plan
        env: *aws_prod
```

### Shared Apply Requirements

```yaml
definitions:
  strict_checks: &strict_checks
    approved:
      enabled: true
      any_of: ["team:platform"]
      any_of_count: 2
    merge_conflicts:
      enabled: true
    status_checks:
      enabled: true

apply_requirements:
  checks:
    - tag_query: "production"
      <<: *strict_checks
    - tag_query: "staging"
      <<: *strict_checks
```

### Shared Directory Configuration

```yaml
definitions:
  shared_modules: &shared_modules
    file_patterns: ["${DIR}/*.tf", "modules/**/*.tf"]
    autoplan: true
    autoapply: false

dirs:
  terraform/networking:
    tags: [networking]
    when_modified: *shared_modules

  terraform/compute:
    tags: [compute]
    when_modified: *shared_modules
```

### Merging Multiple Anchors

```yaml
definitions:
  base_engine: &base_engine
    name: terraform

  pinned_version: &pinned_version
    version: "1.5.0"

workflows:
  - tag_query: ""
    engine:
      <<: [*base_engine, *pinned_version]
```

### Anchor Scoping

Anchors in `definitions` are available in the full configuration file:

```yaml
definitions:
  shared_tags: &shared_tags [aws, managed]

dirs:
  networking:
    tags: *shared_tags
  compute:
    tags: *shared_tags
```

## Best Practices

- Give each anchor a name that tells its purpose, and keep each anchor to one purpose.
- Keep related anchors together in `definitions`, and explain complex anchors in comments.
- To check that the anchors resolve, run `stategraph repo-config`.

## Related

- [YAML anchors](/docs/orchestration/workflows/advanced/yaml-anchors)
- [stategraph repo-config](/docs/reference/orchestration/commands/repo-config)
- [workflows](/docs/reference/orchestration/configuration/workflows)
