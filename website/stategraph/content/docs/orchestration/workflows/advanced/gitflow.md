---
title: Gitflow
description: Implement a Gitflow branching model with Stategraph Orchestration using destination branch tags, branch rules, and one workflow per branch.
order: 1
---


Stategraph Orchestration supports Gitflow, a branching model that gives each branch a role, with three sections of `.stategraph/config.yml`:

- `tags` names the destination branch.
- `destination_branches` controls which branches can open pull requests into which.
- `workflows` runs a different plan and apply for each destination branch.

## The Gitflow branching model

- `main`: the production-ready state of your infrastructure.
- `develop`: the integration branch for feature work, and the staging area before `main`.
- `feature/*`: new work. A feature branch starts from `develop` and merges back into `develop`.
- `release/*`: release preparation. A release branch starts from `develop`. When it is stable, it merges into both `main` and `develop`.
- `hotfix/*`: urgent production fixes. A hotfix branch starts from `main` and merges into both `main` and `develop`.

The [Atlassian Gitflow guide](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow) describes the model in detail.

## Configuring Orchestration for Gitflow

The example uses `main`, `staging`, and `dev` as the long-lived branches.

### 1. Tags

Define a `dest_branch` tag. Its value comes from the destination branch of the pull request. See the [tags reference](/docs/reference/orchestration/configuration/tags).

```yaml
tags:
  dest_branch:
    main: '^main$'
    staging: '^staging$'
    dev: '^dev$'
```

A pull request into `main` gets the `dest_branch:main` tag, a pull request into `staging` gets `dest_branch:staging`, and so on. The values are Lua patterns, not regular expressions.

### 2. Destination branches

Limit which source branches can open pull requests into each destination branch. See the [destination_branches reference](/docs/reference/orchestration/configuration/destination-branches).

```yaml
destination_branches:
  - branch: main
    source_branches: ['staging', 'hotfix/*']
  - branch: staging
    source_branches: ['dev']
  - branch: dev
    source_branches: ['*', '!main', '!staging']
```

- Only `staging` and `hotfix/*` branches can merge into `main`.
- Only `dev` can merge into `staging`.
- Any branch except `main` and `staging` can merge into `dev`. Feature branches land here.

A pull request whose branches match no entry gets no runs. Keep `destination_branches` in step with the branching model that you use.

### 3. Workflows

Match the `dest_branch` tag to run a different workflow for each destination branch. See the [workflows reference](/docs/reference/orchestration/configuration/workflows).

```yaml
workflows:
  - tag_query: 'dest_branch:main'
    plan:
      - type: env
        name: ENVIRONMENT
        cmd: ['echo', 'main']
      - type: init
      - type: plan
    apply:
      - type: env
        name: ENVIRONMENT
        cmd: ['echo', 'main']
      - type: init
      - type: apply
  - tag_query: 'dest_branch:staging'
    plan:
      - type: env
        name: ENVIRONMENT
        cmd: ['echo', 'staging']
      - type: init
      - type: plan
    apply:
      - type: env
        name: ENVIRONMENT
        cmd: ['echo', 'staging']
      - type: init
      - type: apply
  - tag_query: 'dest_branch:dev'
    plan:
      - type: env
        name: ENVIRONMENT
        cmd: ['echo', 'dev']
      - type: init
      - type: plan
    apply:
      - type: env
        name: ENVIRONMENT
        cmd: ['echo', 'dev']
      - type: init
      - type: apply
```

Each workflow sets an `ENVIRONMENT` variable, then runs `init`, `plan`, and `apply`. Your Terraform code or scripts can read the variable to select the backend, variables, or credentials.

### Full example

```yaml
tags:
  dest_branch:
    main: '^main$'
    staging: '^staging$'
    dev: '^dev$'
destination_branches:
  - branch: main
    source_branches: ['staging', 'hotfix/*']
  - branch: staging
    source_branches: ['dev']
  - branch: dev
    source_branches: ['*', '!main', '!staging']
workflows:
  - tag_query: 'dest_branch:main'
    plan:
      - type: env
        name: ENVIRONMENT
        cmd: ['echo', 'main']
      - type: init
      - type: plan
    apply:
      - type: env
        name: ENVIRONMENT
        cmd: ['echo', 'main']
      - type: init
      - type: apply
  - tag_query: 'dest_branch:staging'
    plan:
      - type: env
        name: ENVIRONMENT
        cmd: ['echo', 'staging']
      - type: init
      - type: plan
    apply:
      - type: env
        name: ENVIRONMENT
        cmd: ['echo', 'staging']
      - type: init
      - type: apply
  - tag_query: 'dest_branch:dev'
    plan:
      - type: env
        name: ENVIRONMENT
        cmd: ['echo', 'dev']
      - type: init
      - type: plan
    apply:
      - type: env
        name: ENVIRONMENT
        cmd: ['echo', 'dev']
      - type: init
      - type: apply
```

## Walking through the flow

### Feature

1. Create `feature/add-new-resource` from `dev`.
2. Make your Terraform changes on the feature branch.
3. Open a pull request from `feature/add-new-resource` into `dev`.
4. Orchestration plans the `dev` environment and posts the plan on the pull request.
5. After review and approval, merge. The change is now in `dev`.

### Staging

1. To deploy to staging, open a pull request from `dev` into `staging`.
2. Orchestration plans and applies against the staging environment.
3. If something breaks, fix it on `dev` and repeat.
4. When staging is stable, merge the pull request into `staging`.

### Production

1. To release, open a pull request from `staging` into `main`.
2. Orchestration plans and applies against the production environment.
3. If something breaks, fix it on `staging` and repeat.
4. When production is stable, merge the pull request into `main`.

### Hotfix

1. Create `hotfix/fix-critical-bug` from `main`.
2. Make the fix on the hotfix branch.
3. Open a pull request from `hotfix/fix-critical-bug` into `main`.
4. Orchestration plans and applies against the production environment.
5. After approval and merge, the fix is in production.
6. Merge the hotfix branch back into `dev`, so that future releases include the fix.

## Best practices

- Use the Gitflow branch prefixes, so that the `source_branches` globs match.
- Merge `main` back into `dev` regularly to keep the branches in sync.

## Next steps

- [Tags and tag queries](/docs/orchestration/workflows/advanced/tag-system)
- [Multiple environments](/docs/orchestration/workflows/advanced/multi-environment)
- [destination_branches reference](/docs/reference/orchestration/configuration/destination-branches)
