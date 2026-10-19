---
title: YAML Anchors
description: Reuse engine settings, workflow steps, access policies, and apply requirements across your configuration with YAML anchors in the definitions section.
order: 13
---


YAML anchors let you define a value once in `.stategraph/config.yml` and reuse it in other places. They cut repetition, keep environments consistent, and make a change in one place apply everywhere.

## When to use anchors

Use anchors when you have:

- Several workflows with similar steps.
- The same engine settings repeated per environment.
- A standard sequence of validation steps.
- Access control patterns shared by several tag queries.
- Directory settings shared by several directories.

## Basic syntax

Define anchors in the [`definitions`](/docs/reference/orchestration/configuration/definitions) section, and use them anywhere below it. Stategraph Orchestration ignores the contents of `definitions`. It validates every other key against the configuration schema, so an anchored value must be valid where you use it.

```yaml
definitions:
  std_plan: &std_plan
    - type: init
    - type: plan

workflows:
  - tag_query: ""
    plan: *std_plan
```

## How anchors are resolved

Orchestration resolves anchors, aliases, and the `<<` merge key when it parses the file:

- `*anchor` inserts the anchored value: a scalar, a list, or a map.
- `<<: *anchor` merges the keys of an anchored map into the current map. A key written in the current map wins over a merged key.
- `<<: [*first, *second]` merges several maps. Two `<<:` keys in one map are a parse error.
- Merging is shallow. A nested map is replaced, not merged.
- `*anchor.key` is not valid YAML. Anchor the nested value separately.
- YAML has no list-merge operator. A list alias inside another list creates a nested list, such as `[[init, plan], [checkov]]`, and Orchestration rejects it. This applies to `- *required_steps` in a step list and to `- *base_tags` inside `tags:`.
- To reuse a list, anchor the individual entries and list them, or use the anchored list as the whole value (`tags: *base_tags`) with no added entries.

## Common patterns

### Shared engine configuration

Define the engine once, and override one key where you need to:

```yaml
definitions:
  standard_engine: &standard_engine
    name: terraform
    version: "1.5.7"

workflows:
  - tag_query: "dev"
    engine: *standard_engine

  - tag_query: "prod"
    engine:
      <<: *standard_engine
      version: "1.5.5"
```

### Reusable workflow steps

Anchor each step on its own, so that you can combine the steps into a flat list:

```yaml
definitions:
  # Anchor individual steps, not the surrounding list
  step_init: &step_init
    type: init
  step_fmt: &step_fmt
    type: run
    cmd: ["terraform", "fmt", "-check"]
  step_validate: &step_validate
    type: run
    cmd: ["terraform", "validate"]
  step_checkov: &step_checkov
    type: checkov
  step_tfsec: &step_tfsec
    type: run
    cmd: ["tfsec", "."]

workflows:
  - tag_query: ""
    plan:
      - *step_init
      - *step_fmt
      - *step_validate
      - type: plan
      - *step_checkov
      - *step_tfsec
```

To reuse a full step list, anchor the list and use it as the whole value:

```yaml
definitions:
  full_plan: &full_plan
    - type: init
    - type: plan
    - type: checkov

workflows:
  - tag_query: ""
    plan: *full_plan
```

### Environment-specific settings

The `env` key of a step sets its environment variables. Define the variables once per environment, and use them in the steps that need them:

```yaml
definitions:
  aws_dev: &aws_dev
    AWS_REGION: us-east-1
    AWS_ROLE_ARN: arn:aws:iam::123456789012:role/stategraph-dev
    ENVIRONMENT: development

  aws_staging: &aws_staging
    AWS_REGION: us-east-1
    AWS_ROLE_ARN: arn:aws:iam::123456789012:role/stategraph-staging
    ENVIRONMENT: staging

  aws_prod: &aws_prod
    AWS_REGION: us-east-1
    AWS_ROLE_ARN: arn:aws:iam::123456789012:role/stategraph-prod
    ENVIRONMENT: production

workflows:
  - tag_query: "dev"
    plan:
      - type: init
        env: *aws_dev
      - type: plan
        env: *aws_dev

  - tag_query: "staging"
    plan:
      - type: init
        env: *aws_staging
      - type: plan
        env: *aws_staging

  - tag_query: "production"
    plan:
      - type: init
        env: *aws_prod
      - type: plan
        env: *aws_prod
```

Approval rules are in [`apply_requirements`](/docs/reference/orchestration/configuration/apply-requirements), not in `workflows`. Anchor them the same way:

```yaml
definitions:
  basic_requirements: &basic_requirements
    approved:
      enabled: true
      any_of: ["team:developers"]
      any_of_count: 1
    status_checks:
      enabled: true

  strict_requirements: &strict_requirements
    approved:
      enabled: true
      any_of: ["team:platform"]
      any_of_count: 2
    status_checks:
      enabled: true
    merge_conflicts:
      enabled: true

apply_requirements:
  checks:
    - tag_query: "dev"
      <<: *basic_requirements
    - tag_query: "staging"
      <<: *basic_requirements
    - tag_query: "production"
      <<: *strict_requirements
```

### Standardized access control

Define access patterns once. See the [access_control reference](/docs/reference/orchestration/configuration/access-control).

```yaml
definitions:
  dev_team_access: &dev_team_access
    plan: ["*"]
    apply: ["team:developers", "team:platform"]

  platform_only: &platform_only
    plan: ["*"]
    apply: ["team:platform"]
    apply_force: ["team:sre"]

access_control:
  enabled: true
  policies:
    - tag_query: "dev or staging"
      <<: *dev_team_access

    - tag_query: "production"
      <<: *platform_only

    - tag_query: "infrastructure"
      <<: *platform_only
```

### Workflow templates

Compose different workflows from the same step anchors. A step with `run_on: always` runs even after an earlier step fails:

```yaml
definitions:
  # Base configuration for all workflows
  base_engine: &base_engine
    name: terraform
    version: "1.5.7"

  # Individual step anchors (compose these into flat lists)
  step_init: &step_init
    type: init
  step_fmt: &step_fmt
    type: run
    cmd: ["terraform", "fmt", "-check"]
  step_validate: &step_validate
    type: run
    cmd: ["terraform", "validate"]
  step_plan: &step_plan
    type: plan
  step_checkov: &step_checkov
    type: checkov
    run_on: always
  step_tfsec: &step_tfsec
    type: run
    cmd: ["tfsec", ".", "--format", "json"]
    run_on: always
  step_notify: &step_notify
    type: run
    cmd: ["echo", "Deployment complete"]
    run_on: success

workflows:
  - tag_query: "feature"
    engine: *base_engine
    plan:
      - *step_init
      - *step_fmt
      - *step_validate
      - *step_plan
      - *step_checkov
      - *step_tfsec

  - tag_query: "main"
    engine: *base_engine
    plan:
      - *step_init
      - *step_fmt
      - *step_validate
      - *step_plan
      - *step_checkov
      - *step_tfsec
    apply:
      - type: init
      - type: apply
      - *step_notify
```

### Directory templates

Share `when_modified` settings and tags across directories. `dirs` is a map with directory paths as keys, and globs are allowed:

```yaml
definitions:
  # Anchor individual tag values so they can be composed into flat lists
  tag_aws: &tag_aws aws
  tag_managed: &tag_managed managed

  # Shared when_modified configuration
  with_shared_modules: &with_shared_modules
    file_patterns: ["${DIR}/*.tf", "shared/*.tf"]
    autoplan: true
    autoapply: false

  # Module directories are never planned on their own
  module_config: &module_config
    file_patterns: []

dirs:
  terraform/networking:
    tags:
      - *tag_aws
      - *tag_managed
      - "networking"
      - "core"
    when_modified: *with_shared_modules

  terraform/compute:
    tags:
      - *tag_aws
      - *tag_managed
      - "compute"
      - "application"
    when_modified: *with_shared_modules

  modules/**:
    when_modified: *module_config
```

## Advanced techniques

### Merging several anchors

Give one `<<:` key a list of anchors. The `version` key written in the map overrides the merged value:

```yaml
definitions:
  base: &base
    name: terraform

  pinned: &pinned
    version: "1.5.5"

  no_outputs: &no_outputs
    outputs:
      collect: false

workflows:
  - tag_query: "production"
    engine:
      <<: [*base, *pinned, *no_outputs]
      version: "1.5.7"
```

### Per-environment step lists

Anchor each step, and make one list per environment. The production list repeats the base entries, but each step is defined only once.

```yaml
definitions:
  # Anchor individual steps
  step_init: &step_init
    type: init
  step_plan: &step_plan
    type: plan
  step_checkov: &step_checkov
    type: checkov
  step_compliance: &step_compliance
    type: run
    cmd: ["compliance-check"]

  # Development workflow
  dev_plan: &dev_plan
    - *step_init
    - *step_plan

  # Production workflow with compliance checks
  prod_plan: &prod_plan
    - *step_init
    - *step_plan
    - *step_checkov
    - *step_compliance

workflows:
  - tag_query: "dev"
    plan: *dev_plan

  - tag_query: "production"
    plan: *prod_plan
```

## Best practices

- Name anchors by purpose, for example `step_checkov`, not `s1`.
- Keep related anchors together in `definitions`.
- Add a comment to a complex anchor, so that the next reader knows where it is used.
- Start simple, and add anchors when repetition appears.
- Check the result: comment [`stategraph repo-config`](/docs/reference/orchestration/commands/repo-config) on a pull request. The reply shows the configuration with every anchor resolved.

## Example: complete multi-environment setup

```yaml
definitions:
  # Terraform version
  tf_engine: &tf_engine
    name: terraform
    version: "1.5.7"

  # Individual step anchors (compose into flat lists below)
  step_init: &step_init
    type: init
  step_fmt: &step_fmt
    type: run
    cmd: ["terraform", "fmt", "-check"]
  step_validate: &step_validate
    type: run
    cmd: ["terraform", "validate"]
  step_plan: &step_plan
    type: plan
  step_checkov: &step_checkov
    type: checkov

  # Environment credentials
  dev_env: &dev_env
    AWS_ROLE_ARN: arn:aws:iam::111111111111:role/stategraph-dev
    AWS_REGION: us-east-1

  prod_env: &prod_env
    AWS_ROLE_ARN: arn:aws:iam::222222222222:role/stategraph-prod
    AWS_REGION: us-east-1

  # Access patterns
  dev_access: &dev_access
    plan: ["*"]
    apply: ["team:developers"]

  prod_access: &prod_access
    plan: ["*"]
    apply: ["team:platform"]
    apply_force: ["team:sre"]

  # Approval rules
  dev_checks: &dev_checks
    approved:
      enabled: true
      any_of: ["team:developers"]
      any_of_count: 1

  prod_checks: &prod_checks
    approved:
      enabled: true
      any_of: ["team:platform"]
      any_of_count: 2
    status_checks:
      enabled: true

workflows:
  - tag_query: "dev"
    engine: *tf_engine
    plan:
      - *step_init
      - *step_fmt
      - *step_validate
      - type: plan
        env: *dev_env
      - *step_checkov
    apply:
      - *step_init
      - type: apply
        env: *dev_env

  - tag_query: "production"
    engine: *tf_engine
    plan:
      - *step_init
      - *step_fmt
      - *step_validate
      - type: plan
        env: *prod_env
      - *step_checkov
    apply:
      - *step_init
      - type: apply
        env: *prod_env

apply_requirements:
  checks:
    - tag_query: "dev"
      <<: *dev_checks
    - tag_query: "production"
      <<: *prod_checks

access_control:
  enabled: true
  policies:
    - tag_query: "dev"
      <<: *dev_access
    - tag_query: "production"
      <<: *prod_access
```

Every setting is defined once, and the file is accepted as written.

## Next steps

- [definitions reference](/docs/reference/orchestration/configuration/definitions)
- [workflows reference](/docs/reference/orchestration/configuration/workflows)
- [Multiple environments](/docs/orchestration/workflows/advanced/multi-environment)
