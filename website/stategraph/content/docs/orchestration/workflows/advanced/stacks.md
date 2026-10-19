---
title: Grouping Infrastructure with Stacks
description: Group directories and workspaces into named stacks with plan_after, apply_after, modified_by, and auto_apply rules to build a deployment pipeline.
order: 12
---


Stacks group directories and workspaces under a name, and set rules for when each group can plan and apply relative to other groups. This guide builds a deployment pipeline for a three-tier application in three environments, one step at a time. The [stacks reference](/docs/reference/orchestration/configuration/stacks) lists every key.

## Why stacks

Some example uses:

1. Development and production can plan together, but production can apply only after development applies.
2. An operation should run automatically after a change applies, for example an Ansible playbook.
3. Directory B depends on directory A, and B should plan and apply each time that A changes.

## Core concepts

Define stacks in the `stacks` section of `.stategraph/config.yml`.

1. There are two kinds of stack. A regular stack is a set of directories and workspaces that a tag query selects. A nested stack is a list of other stacks.
2. Each directory and workspace belongs to exactly one stack.
3. Stack rules are transitive. If stack C must plan after B applies, and B must plan after A applies, then a change to A and C (not B) still orders C after A.
4. Stacks can define variables. They are available in the `workflows` section as `${name}`, and as environment variables in the run.

## Building the pipeline

### Step 1: Organize the components

Group the Terraform modules by environment and layer:

```text
infrastructure/
├── ansible/            # Operations on infrastructure
├── base/
│   └── networking/     # VPCs, subnets, security groups
├── dev/
│   ├── database/       # Database instances
│   ├── compute/        # Container or Kubernetes clusters
│   └── application/    # Application deployments
├── staging/
│   ├── database/
│   ├── compute/
│   └── application/
└── production/
    ├── database/
    ├── compute/
    └── application/
```

### Step 2: One stack per environment

Start with one stack per environment. The rules take effect only when several stacks change in the same pull request. A change to `dev` alone does not make `staging` run. When `dev` and `staging` change together, `staging` can apply only after `dev`.

```yaml
dirs:
  'dev/**':
    tags: [dev]
  'staging/**':
    tags: [staging]
  'production/**':
    tags: [production]

stacks:
  names:
    dev:
      tag_query: 'dev'
      variables:
        environment: development
      rules:
        auto_apply: true

    staging:
      tag_query: 'staging'
      variables:
        environment: staging
      rules:
        apply_after:
          - dev

    production:
      tag_query: 'production'
      variables:
        environment: production
      rules:
        apply_after:
          - staging

workflows:
  - tag_query: ''
    environment: '${environment}'
```

Changes now flow from `dev` to `staging` to `production` when a change reaches more than one of them. The `environment` stack variable selects the [GitHub environment](/docs/orchestration/security/github-environments) for each run.

### Step 3: Layers inside each environment

In step 2, all components of an environment can run at the same time. But the database should run before compute, and compute before the application. This step creates one stack per layer, and nests the layers in the `dev`, `staging`, and `production` stacks. The `environment` variable and the rules that order the environments move to the parent stack.

```yaml
stacks:
  names:
    dev-database:
      tag_query: 'dir:dev/database'
      variables:
        layer: database

    dev-compute:
      tag_query: 'dir:dev/compute'
      variables:
        layer: compute
      rules:
        plan_after:
          - dev-database

    dev-application:
      tag_query: 'dir:dev/application'
      variables:
        layer: application
      rules:
        plan_after:
          - dev-compute

    dev:
      stacks:
        - dev-database
        - dev-compute
        - dev-application
      variables:
        environment: development
      rules:
        auto_apply: true

    staging-database:
      tag_query: 'dir:staging/database'
      variables:
        layer: database

    staging-compute:
      tag_query: 'dir:staging/compute'
      variables:
        layer: compute
      rules:
        plan_after:
          - staging-database

    staging-application:
      tag_query: 'dir:staging/application'
      variables:
        layer: application
      rules:
        plan_after:
          - staging-compute

    staging:
      stacks:
        - staging-database
        - staging-compute
        - staging-application
      variables:
        environment: staging
      rules:
        apply_after:
          - dev

    production-database:
      tag_query: 'dir:production/database'
      variables:
        layer: database

    production-compute:
      tag_query: 'dir:production/compute'
      variables:
        layer: compute
      rules:
        plan_after:
          - production-database

    production-application:
      tag_query: 'dir:production/application'
      variables:
        layer: application
      rules:
        plan_after:
          - production-compute

    production:
      stacks:
        - production-database
        - production-compute
        - production-application
      variables:
        environment: production
      rules:
        apply_after:
          - staging

workflows:
  - tag_query: ''
    environment: '${environment}'
```

### Step 4: Shared infrastructure

The `base` directory holds infrastructure that every environment depends on. When `base` changes, every downstream stack should run, even without a change of its own. The `modified_by` rule on each dependent stack does that.

```yaml
stacks:
  names:
    base-networking:
      tag_query: 'dir:base/networking'

    base:
      stacks:
        - base-networking

    dev-database:
      tag_query: 'dir:dev/database'
      variables:
        layer: database

    dev-compute:
      tag_query: 'dir:dev/compute'
      variables:
        layer: compute
      rules:
        plan_after:
          - dev-database

    dev-application:
      tag_query: 'dir:dev/application'
      variables:
        layer: application
      rules:
        plan_after:
          - dev-compute

    dev:
      stacks:
        - dev-database
        - dev-compute
        - dev-application
      variables:
        environment: development
      rules:
        auto_apply: true
        modified_by:
          - base

    staging-database:
      tag_query: 'dir:staging/database'
      variables:
        layer: database

    staging-compute:
      tag_query: 'dir:staging/compute'
      variables:
        layer: compute
      rules:
        plan_after:
          - staging-database

    staging-application:
      tag_query: 'dir:staging/application'
      variables:
        layer: application
      rules:
        plan_after:
          - staging-compute

    staging:
      stacks:
        - staging-database
        - staging-compute
        - staging-application
      variables:
        environment: staging
      rules:
        apply_after:
          - dev
        modified_by:
          - base

    production-database:
      tag_query: 'dir:production/database'
      variables:
        layer: database

    production-compute:
      tag_query: 'dir:production/compute'
      variables:
        layer: compute
      rules:
        plan_after:
          - production-database

    production-application:
      tag_query: 'dir:production/application'
      variables:
        layer: application
      rules:
        plan_after:
          - production-compute

    production:
      stacks:
        - production-database
        - production-compute
        - production-application
      variables:
        environment: production
      rules:
        apply_after:
          - staging
        modified_by:
          - base

workflows:
  - tag_query: 'stack_name:base'
  - tag_query: ''
    environment: '${environment}'
```

Each stack has an implicit `stack_name:<name>` tag. The first workflow uses it to give `base` its own workflow entry, without a GitHub environment.

### Step 5: Run Ansible after production applies

To run something after an apply, combine `modified_by` with `auto_apply`. The `ansible` stack below runs each time that `production` changes. `auto_apply` applies automatically only when every apply requirement of the stack passes. If not, it waits for a person.

```yaml
stacks:
  names:
    ansible:
      tag_query: 'dir:ansible'
      rules:
        auto_apply: true
        modified_by:
          - production

    base-networking:
      tag_query: 'dir:base/networking'

    base:
      stacks:
        - base-networking

    dev-database:
      tag_query: 'dir:dev/database'
      variables:
        layer: database

    dev-compute:
      tag_query: 'dir:dev/compute'
      variables:
        layer: compute
      rules:
        plan_after:
          - dev-database

    dev-application:
      tag_query: 'dir:dev/application'
      variables:
        layer: application
      rules:
        plan_after:
          - dev-compute

    dev:
      stacks:
        - dev-database
        - dev-compute
        - dev-application
      variables:
        environment: development
      rules:
        auto_apply: true
        modified_by:
          - base

    staging-database:
      tag_query: 'dir:staging/database'
      variables:
        layer: database

    staging-compute:
      tag_query: 'dir:staging/compute'
      variables:
        layer: compute
      rules:
        plan_after:
          - staging-database

    staging-application:
      tag_query: 'dir:staging/application'
      variables:
        layer: application
      rules:
        plan_after:
          - staging-compute

    staging:
      stacks:
        - staging-database
        - staging-compute
        - staging-application
      variables:
        environment: staging
      rules:
        apply_after:
          - dev
        modified_by:
          - base

    production-database:
      tag_query: 'dir:production/database'
      variables:
        layer: database

    production-compute:
      tag_query: 'dir:production/compute'
      variables:
        layer: compute
      rules:
        plan_after:
          - production-database

    production-application:
      tag_query: 'dir:production/application'
      variables:
        layer: application
      rules:
        plan_after:
          - production-compute

    production:
      stacks:
        - production-database
        - production-compute
        - production-application
      variables:
        environment: production
      rules:
        apply_after:
          - staging
        modified_by:
          - base

workflows:
  - tag_query: 'stack_name:ansible'
    engine:
      name: custom
      plan: ['${TERRATEAM_ROOT}/bin/ansible-plan']
      apply: ['${TERRATEAM_ROOT}/bin/ansible-apply']
  - tag_query: 'stack_name:base'
  - tag_query: ''
    environment: '${environment}'
```

The `ansible` stack uses a [custom engine](/docs/orchestration/workflows/advanced/engine-setup), with your own scripts as the plan and apply commands.

## The default stack

A workspace that matches more than one stack is a configuration error. A workspace that matches no stack goes into the implicit `default` stack. If you define a stack named `default`, it replaces the implicit stack and behaves like any other stack. A workspace that then matches no stack is a configuration error.

## Stacks and depends_on

A [`depends_on`](/docs/orchestration/workflows/advanced/layered-runs) can name only directories in the same stack, or in a stack that shares a nested stack with it. A directory in an unrelated stack is a configuration error. To order two unrelated stacks, use `plan_after` and `apply_after`. To let directories in two stacks depend on each other, put both stacks in one nested stack.

## Stacks in the console

In the console, the **Stacks** page shows the stacks of each open pull request in plan order, with the `default` stack last. It shows the live plan and apply state of each dirspace.

## Next steps

- [stacks reference](/docs/reference/orchestration/configuration/stacks)
- [Layered runs](/docs/orchestration/workflows/advanced/layered-runs): ordering inside a stack.
- [Multiple environments](/docs/orchestration/workflows/advanced/multi-environment)
- [Stacks API](/docs/reference/api/stacks)
