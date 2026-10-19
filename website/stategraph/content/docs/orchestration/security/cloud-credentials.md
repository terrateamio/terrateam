---
title: Cloud credentials
description: Authenticate Stategraph Orchestration runs to AWS, Azure, and GCP with OIDC, static credentials, or a custom credential script.
order: 2
---


Each plan and apply that Stategraph Orchestration runs on your CI runners needs cloud credentials. Give them with OIDC, static credentials, or a script that generates credentials at run time. Use OIDC where the provider supports it.

## OIDC

The `oidc` step authenticates to a cloud provider for the run. Compared with static credentials:

- Credentials are issued for each run and expire quickly, which limits the damage of a leak.
- No long-lived keys are in your repository settings.
- You rotate nothing by hand.
- Each workflow can assume a different role, so permissions stay narrow.

### Basic OIDC configuration

Add an `oidc` step before `init` in the plan and apply step lists. A step is one action in a workflow, such as authentication, initialization, or a Terraform command.

!!! note "Storing sensitive values"
    Store sensitive values as GitHub Actions secrets, GitLab CI/CD variables, or in a secrets manager. Never commit them. Refer to GitHub and GitLab secrets with the `${SECRET_NAME}` syntax. They are decrypted only inside the run.

Workflow form:

```yaml
workflows:
  - tag_query: "dir:aws"
    plan:
      - type: oidc
        provider: aws
        role_arn: ${AWS_ROLE_ARN}
      - type: init
      - type: plan
    apply:
      - type: oidc
        provider: aws
        role_arn: ${AWS_ROLE_ARN}
      - type: init
      - type: apply
```

Hook form:

```yaml
hooks:
  all:
    pre:
      - type: oidc
        provider: aws
        role_arn: ${AWS_ROLE_ARN}
```

Both forms authenticate to AWS with the role in `AWS_ROLE_ARN`. Hooks run before or after each plan and apply. Workflows set the steps for the directories that their `tag_query` matches.

For the provider-specific keys, see the [workflows reference](/docs/reference/orchestration/configuration/workflows). For the provider-side setup, see the [cloud provider guides](/docs/orchestration/cloud-providers/aws/oidc).

### Different roles for plan and apply

Use one role for plan and another for apply, so that the plan role can be read-only:

```yaml
workflows:
  - tag_query: "dir:aws"
    plan:
      - type: oidc
        provider: aws
        role_arn: ${AWS_PLAN_ROLE_ARN}
      - type: init
      - type: plan
    apply:
      - type: oidc
        provider: aws
        role_arn: ${AWS_APPLY_ROLE_ARN}
      - type: init
      - type: apply
```

### Multiple cloud providers

To authenticate to several providers in one workflow, add one `oidc` step for each:

```yaml
workflows:
  - tag_query: "dir:multi-cloud"
    plan:
      - type: oidc
        provider: aws
        role_arn: ${AWS_ROLE_ARN}
      - type: oidc
        provider: azure
        client_id: ${ARM_CLIENT_ID}
        tenant_id: ${ARM_TENANT_ID}
      - type: oidc
        provider: gcp
        service_account: ${GCP_SERVICE_ACCOUNT}
        workload_identity_provider: ${GCP_WORKLOAD_IDENTITY_PROVIDER}
      - type: init
      - type: plan
    apply:
      - type: oidc
        provider: aws
        role_arn: ${AWS_ROLE_ARN}
      - type: oidc
        provider: azure
        client_id: ${ARM_CLIENT_ID}
        tenant_id: ${ARM_TENANT_ID}
      - type: oidc
        provider: gcp
        service_account: ${GCP_SERVICE_ACCOUNT}
        workload_identity_provider: ${GCP_WORKLOAD_IDENTITY_PROVIDER}
      - type: init
      - type: apply
```

### Roles per directory

To give each environment its own role, match its directories with [tag queries](/docs/reference/orchestration/configuration/tag-queries):

```yaml
workflows:
  - tag_query: "dir:aws/production"
    plan:
      - type: oidc
        provider: aws
        role_arn: ${AWS_PRODUCTION_ROLE_ARN}
      - type: init
      - type: plan
    apply:
      - type: oidc
        provider: aws
        role_arn: ${AWS_PRODUCTION_ROLE_ARN}
      - type: init
      - type: apply
  - tag_query: "dir:aws/staging"
    plan:
      - type: oidc
        provider: aws
        role_arn: ${AWS_STAGING_ROLE_ARN}
      - type: init
      - type: plan
    apply:
      - type: oidc
        provider: aws
        role_arn: ${AWS_STAGING_ROLE_ARN}
      - type: init
      - type: apply
```

Orchestration uses the first workflow whose `tag_query` matches a directory, so `aws/production` and `aws/staging` each get their own role.

## Static credentials

!!! warning "Security consideration"
    Static credentials are long-lived and need manual rotation. Rotate static and generated credentials on a schedule.

### Store the credentials

On GitHub, store the keys as repository secrets. With the GitHub CLI:

```bash
gh secret set AWS_ACCESS_KEY_ID --body "your-access-key"
gh secret set AWS_SECRET_ACCESS_KEY --body "your-secret-key"
```

On GitLab, add `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as masked CI/CD variables in the project, under **Settings > CI/CD > Variables**.

Orchestration gives repository secrets and CI/CD variables to the runner as environment variables, and the provider reads them. See [environment variables](/docs/orchestration/configuration/environment-variables) and the [static credentials guide](/docs/orchestration/cloud-providers/aws/static-credentials).

### Apply least privilege

Give the static identity only the permissions that its runs need. This example AWS IAM policy allows reads from a state bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::my-terraform-state",
        "arn:aws:s3:::my-terraform-state/*"
      ]
    }
  ]
}
```

## Custom credential scripts

A script can generate credentials at run time, for example by assuming a role with a session name that identifies the run. An `env` step with `method: source` runs the script and exports the variables that it sets.

!!! tip "Script requirements"
    A credential script should request the fewest permissions, use the shortest practical expiry, and log each use of the credentials for audit. Its identity should assume only the roles that it needs, and each assumed role should have only the permissions of its task. Use separate roles for plan and apply.

An example script:

```bash
#!/bin/bash
# generate-aws-credentials.sh

environment=$1    # e.g. "production" or "staging"
access_level=$2   # e.g. "read-only" or "read-write"

aws sts assume-role \
  --role-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${environment}-${access_level}" \
  --role-session-name "stategraph-${environment}"
```

Source it in the workflow:

```yaml
workflows:
  - tag_query: "dir:aws/production"
    plan:
      - type: env
        method: source
        cmd: ["./generate-aws-credentials.sh", "production", "read-only"]
      - type: init
      - type: plan
```

## Next steps

- [Hardening AWS OIDC](/docs/orchestration/security/hardening-aws-oidc): restrict which runs can assume the role.
- [GitHub Environments](/docs/orchestration/security/github-environments): scope secrets to an environment.
- [Cloud providers](/docs/orchestration/cloud-providers/aws): provider-side OIDC and static credential setup.
