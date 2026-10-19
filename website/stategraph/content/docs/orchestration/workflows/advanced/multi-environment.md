---
title: Multiple Environments
description: Manage production, staging, and QA in one repository with separate directories, workspaces, or tfvars files, and target each with tag queries.
order: 11
---


Stategraph Orchestration supports three layouts for several environments, such as production, staging, and QA, in one repository: a directory per environment, a workspace per environment, or a `.tfvars` file per environment. Each layout uses tags and tag queries to target one environment.

## Comparing the approaches

| Approach | Advantages | Disadvantages |
|----------|------------|---------------|
| Separate directories | Clear separation of code and resources. Each environment changes on its own, so a change is less likely to reach several environments at once. State per environment is easy to manage. Simple to understand and to configure. | Code is duplicated. Sharing modules and logic is harder. |
| Directories and workspaces | Less duplication. Logic is shared. Flexible. | Workspaces can confuse people. State must be managed carefully. |
| tfvars files | One code base, only variables differ. Adding an environment is easy. | State files can overlap if you are not careful. Per-environment changes are harder to audit. |

## Separate directories

The simplest layout gives each environment its own directory:

```text
.
├── production
│   └── main.tf
├── qa
│   └── main.tf
└── staging
    └── main.tf
```

### Configuration

Tag each directory, and give each tag its own workflow in `.stategraph/config.yml`:

```yaml
dirs:
  production:
    tags: [production]
  qa:
    tags: [qa]
  staging:
    tags: [staging]
workflows:
  - tag_query: production
    plan:
      - type: init
      - type: plan
    apply:
      - type: init
      - type: apply
  - tag_query: qa
    plan:
      - type: init
      - type: plan
    apply:
      - type: init
      - type: apply
  - tag_query: staging
    plan:
      - type: init
      - type: plan
    apply:
      - type: init
      - type: apply
```

- Each environment directory is in `dirs` with its own tag.
- Each workflow matches one tag with `tag_query`.
- Each workflow has its own `init`, `plan`, and `apply` steps, so environments can differ later.

### Triggering operations

To target one environment, put its tag after the command. To plan `production`, comment:

```text
stategraph plan production
```

To apply `qa`, comment:

```text
stategraph apply qa
```

Orchestration runs the operation against the directory with the tag.

## Directories and workspaces

A directory holds a logical group of resources, such as `ec2` or `rds`, with a Terraform workspace per environment:

```yaml
dirs:
  ec2:
    tags: [ec2]
    workspaces:
      development:
        tags: [development]
      production:
        tags: [production]
```

The `ec2` directory has two workspaces, `development` and `production`. The directory and each workspace carry tags, so a [tag query](/docs/orchestration/workflows/advanced/tag-system) such as `ec2 and production` targets one environment. Each workspace also gets an implicit `workspace:<name>` tag.

## tfvars files

One directory holds the code, and one `.tfvars` file per environment holds the variable values. The examples use a single `aws` directory and two environments, `qa` and `production`.

### Shared Terraform state

Both environments share one state file.

#### Directory structure

```text
.
└── aws
    ├── main.tf
    ├── production.tfvars
    └── qa.tfvars
```

#### Backend configuration

`main.tf` uses one state file with the `local` backend:

```hcl
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

resource "null_resource" "foobar" {
}
```

!!! note "Example only"
    The `local` backend is for development. In production, use a remote backend such as S3, or [Infrastructure as a Database](/docs/infrastructure-as-a-database).

#### Configuration

`.stategraph/config.yml`:

```yaml
when_modified:
  autoplan: false
dirs:
  aws:
    create_and_select_workspace: false
    tags: [aws]
    workspaces:
      qa:
        tags: [qa]
      production:
        tags: [production]
workflows:
  - tag_query: aws qa
    plan:
      - type: init
      - type: plan
        extra_args: ["-var-file=qa.tfvars"]
  - tag_query: aws production
    plan:
      - type: init
      - type: plan
        extra_args: ["-var-file=production.tfvars"]
```

`create_and_select_workspace: false` keeps Terraform on its default workspace. The Orchestration workspaces `qa` and `production` only carry tags and select the `.tfvars` file.

#### Pull request behavior

`autoplan` is `false`, so a pull request that changes the `aws` directory starts nothing on its own. To plan `qa`, comment:

```text
stategraph plan aws qa
```

To apply `qa`, comment:

```text
stategraph apply aws qa
```

To plan `production`, comment:

```text
stategraph plan aws production
```

To apply `production`, comment:

```text
stategraph apply aws production
```

### Separate Terraform state

Each environment gets its own state file.

#### Directory structure

```text
.
└── aws
    ├── backend-production.conf
    ├── backend-qa.conf
    ├── main.tf
    ├── production.tfvars
    └── qa.tfvars
```

#### Backend configuration

`main.tf` has a partial backend block. A per-environment file completes it during `terraform init`:

`main.tf`

```hcl
terraform {
  backend "local" {
  }
}

resource "null_resource" "foobar" {
}
```

`backend-qa.conf`

```text
path = "qa.tfstate"
```

`backend-production.conf`

```text
path = "production.tfstate"
```

#### Configuration

`.stategraph/config.yml`:

```yaml
when_modified:
  autoplan: true
dirs:
  aws:
    create_and_select_workspace: false
    tags: [aws]
    workspaces:
      qa:
        tags: [qa]
      production:
        tags: [production]
workflows:
  - tag_query: aws qa
    plan:
      - type: init
        extra_args: ["-backend-config=backend-qa.conf"]
      - type: plan
        extra_args: ["-var-file=qa.tfvars"]
    apply:
      - type: init
        extra_args: ["-backend-config=backend-qa.conf"]
      - type: apply
  - tag_query: aws production
    plan:
      - type: init
        extra_args: ["-backend-config=backend-production.conf"]
      - type: plan
        extra_args: ["-var-file=production.tfvars"]
    apply:
      - type: init
        extra_args: ["-backend-config=backend-production.conf"]
      - type: apply
```

#### Pull request behavior

`autoplan` is on, so a pull request that changes the `aws` directory starts two plans: one for `qa` and one for `production`. Each plan has its own `-backend-config` and `-var-file` arguments. To plan `qa`, comment:

```text
stategraph plan aws qa
```

To plan `production`, comment:

```text
stategraph plan aws production
```

To plan both environments, comment:

```text
stategraph plan aws
```

To apply `qa`, comment:

```text
stategraph apply aws qa
```

To apply `production`, comment:

```text
stategraph apply aws production
```

## Best practices

- Use one naming convention for directories, workspaces, and `.tfvars` files, so that the name shows the environment.
- Prefer a separate state per environment. It limits the blast radius of a mistake.

## Next steps

- [Tags and tag queries](/docs/orchestration/workflows/advanced/tag-system)
- [Gitflow](/docs/orchestration/workflows/advanced/gitflow): branch-based environments.
- [Stacks](/docs/orchestration/workflows/advanced/stacks): order environments so production applies after staging.
- [dirs reference](/docs/reference/orchestration/configuration/dirs)
