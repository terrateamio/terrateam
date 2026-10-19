---
title: Secrets and Variables
description: Pass secrets, environment variables, and .tfvars files to Terraform runs through GitHub secrets, GitLab CI/CD variables, hooks, and workflows.
order: 3
---


You pass secrets and variables to Terraform with GitHub secrets and variables, GitLab CI/CD variables, `env` steps in hooks and workflows, or `.tfvars` files. Stategraph Orchestration runs Terraform on your GitHub Actions or GitLab CI runners for each pull request, so these values reach Terraform as in any other CI job. Use the one that fits your workflow.

## Defining secrets

GitHub [secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets) and [variables](https://docs.github.com/en/actions/learn-github-actions/variables), and GitLab [CI/CD variables](https://docs.gitlab.com/ee/ci/variables/), become environment variables in the runner, where your Terraform code and your workflow steps read them. Create them with the CLI or the web interface of your VCS.

### GitHub

#### Using the GitHub CLI

Create a secret named `AWS_ACCESS_KEY_ID`:

```bash
gh secret set AWS_ACCESS_KEY_ID --body "<YOUR_ACTUAL_AWS_ACCESS_KEY_ID>"
```

#### Using the GitHub web interface

1. Open the repository where Orchestration is installed.
2. Go to **Settings**, then **Secrets and variables**, then **Actions**.
3. Click **New repository secret**.
4. Enter the **Name** (`AWS_ACCESS_KEY_ID`) and the **Secret value**.
5. Click **Add secret**.

### GitLab

#### Using the GitLab web interface

1. Open your GitLab project.
2. Go to **Settings**, then **CI/CD**, then **Variables**.
3. Click **Add variable**.
4. Enter the **Key** (`AWS_ACCESS_KEY_ID`) and the **Value**.
5. Select **Mask variable** to hide it in logs.
6. Click **Add variable**.

Orchestration starts plan pipelines on the merge request's source branch. GitLab passes a variable marked **Protect variable** only to pipelines on protected branches and tags, so leave that option cleared for each variable that a plan needs.

## Using secrets in Terraform

CI secrets are usually uppercase, and Terraform variables are usually lowercase. The runner copies each environment variable that starts with `TF_VAR_` to a name with the rest in lowercase:

- The uppercase variable stays as it is.
- If the lowercase name already exists, nothing changes.

For example, the secret `TF_VAR_DATABASE_PASSWORD` becomes `TF_VAR_database_password`, which Terraform maps to the variable `database_password`:

```hcl
variable "database_password" {
  description = "Password for database connection"
  type        = string
  sensitive   = true
}

resource "aws_db_instance" "example" {
  # Other configuration...
  password = var.database_password
}
```

### Security

Your VCS stores secrets encrypted, and the CI platform decrypts them only in the runner of the job. The Orchestration server does not store unencrypted secrets.

Masking is different on each CI platform:

- GitHub: the runner masks each GitHub Actions secret in the job log, and in the plan and apply output that it posts to the pull request.
- GitLab: GitLab masks the variables marked **Mask variable** in the job log.

On both platforms, the runner masks the credentials of the `oidc` hook, and the values of `env` hooks and steps marked `sensitive`. Declare Terraform variables that hold secrets with `sensitive = true`, so that Terraform hides them in the plan output.

Plan files can contain sensitive values. For where they are stored, see [Plan file storage](/docs/orchestration/security/plan-file-storage).

## Hooks and workflows

You can also set environment variables in `.stategraph/config.yml`, with [hooks](/docs/reference/orchestration/configuration/hooks) and [workflows](/docs/reference/orchestration/configuration/workflows).

### Hooks

An `env` hook sets a variable at the start of an operation:

```yaml
hooks:
  plan:
    pre:
      - type: env
        name: FOO
        cmd: ['echo', 'BAR']
  apply:
    pre:
      - type: env
        name: BAZ
        cmd: ['echo', 'QUX']
```

The output of the command becomes the value, so you can compute a variable. This one gets the current Git branch:

```yaml
hooks:
  plan:
    pre:
      - type: env
        name: CURRENT_GIT_BRANCH
        cmd: ['bash', '-c', 'echo $(git rev-parse --abbrev-ref HEAD)']
```

A GitLab CI job checks out a detached commit, so there this command prints `HEAD`. On GitLab, read the predefined `CI_COMMIT_REF_NAME` variable.

### Workflows

An `env` step sets a variable at the start of each plan and apply, for the directories that the workflow matches:

```yaml
workflows:
  - tag_query: ""
    plan:
      - type: init
      - type: env
        name: FOO
        cmd: ["echo", "BAR"]
      - type: plan
    apply:
      - type: init
      - type: env
        name: FOO
        cmd: ["echo", "BAR"]
      - type: apply
```

## .tfvars files

Terraform reads variable values from `.tfvars` files. Pass one to the plan step with `extra_args`:

```yaml
workflows:
  - tag_query: ""
    plan:
      - type: init
      - type: plan
        extra_args: ["-var-file=qa.tfvars"]
    apply:
      - type: init
      - type: apply
```

An example `qa.tfvars`:

```hcl
region        = "us-west-2"
instance_type = "t3.micro"
vpc_cidr      = "10.0.0.0/16"
environment   = "qa"
```

The plan step reads `qa.tfvars`. The apply step uses the stored plan, so the same values apply.

## Next Steps

- [Environment variables](/docs/orchestration/configuration/environment-variables): the built-in variables the runner sets.
- [Cloud credentials](/docs/orchestration/security/cloud-credentials): OIDC and static credentials for your cloud provider.
- [hooks](/docs/reference/orchestration/configuration/hooks) and [workflows](/docs/reference/orchestration/configuration/workflows): every step type.
