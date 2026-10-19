---
title: Security best practices
description: Recommended practices for running Stategraph Orchestration in production. Isolate secrets, control who can plan and apply, and audit every change.
order: 1
---


These practices limit what a Stategraph Orchestration run can reach and who can start it.

## Mitigating risks from untrusted HCL

Orchestration runs `terraform plan` on your CI runners for each pull request, and a plan of untrusted HCL is code execution. With the `external` provider, `null_resource` provisioners, or other providers, anyone who can open a pull request can run commands on the runner. That gives them the credentials that the runner holds for the plan, and through them, access to your production environment.

### Isolate secrets

Combine [GitHub Environments](/docs/orchestration/security/github-environments) with [access control](/docs/reference/orchestration/configuration/access-control), so that only runs from trusted people reach production secrets:

```yaml
workflows:
  - tag_query: 'dir:production'
    environment: production
access_control:
  enabled: true
  apply_require_all_dirspace_access: true
  plan_require_all_dirspace_access: false
  terrateam_config_update: ['team:admins']
  unlock: ['team:admins']
  policies:
    - tag_query: 'dir:production'
      plan: ['team:developers']
      apply: ['team:sre']
```

This configuration:

- binds the `production` workflow to the `production` GitHub Environment, so its secrets and variables are available only to that workflow
- requires access to each targeted [dirspace](/docs/get-started/core-concepts) for an apply
- lets only the `admins` team change the configuration and unlock
- gives `developers` plan access and `sre` apply access for production

Access control is an Enterprise feature. See [Editions](/docs/get-started/editions).

### Enforce policy from one place

Use [centralized configuration](/docs/orchestration/governance/centralized-config) to set defaults for each repository in the organization, and policy that the `.stategraph/config.yml` of a repository cannot override.

## Secure workflow design

### Use OIDC

Avoid long-lived static keys. The `oidc` step issues credentials that expire after the run:

```yaml
workflows:
  - tag_query: 'dir:production'
    plan:
      - type: oidc
        provider: aws
        role_arn: ${AWS_ROLE_PROD_ARN}
      - type: init
      - type: plan
    apply:
      - type: oidc
        provider: aws
        role_arn: ${AWS_ROLE_PROD_ARN}
      - type: init
      - type: apply
```

See [Cloud credentials](/docs/orchestration/security/cloud-credentials) and [Hardening AWS OIDC](/docs/orchestration/security/hardening-aws-oidc).

### Enforce policy before apply

Check each plan against policy with Open Policy Agent. This workflow copies policies from a private bucket and runs `conftest` against the plan:

```yaml
workflows:
  - tag_query: 'dir:production'
    plan:
      - type: oidc
        provider: aws
        role_arn: ${AWS_ROLE_PROD_ARN}
      - type: run
        cmd: ['aws', 's3', 'sync', 's3://acme-sre-private-bucket/opa/policies/', '/tmp/policies/']
      - type: init
      - type: plan
      - type: env
        name: CONFTEST_POLICY
        cmd: ['echo', '/tmp/policies/']
      - type: conftest
```

A failed `conftest` step fails the plan, so you cannot apply a change that does not comply. See [OPA](/docs/orchestration/external-tools/opa) and [Security scanning](/docs/infrastructure-as-a-database/security).

### Detect drift

Turn on [drift detection](/docs/orchestration/governance/drift-detection) to find changes made outside Terraform:

```yaml
hooks:
  plan:
    post:
      - type: drift_create_issue
drift:
  enabled: true
  schedules:
    default:
      tag_query: ''
      schedule: daily
```

This runs drift detection daily, and opens an issue in the repository when it finds drift. On GitLab, the issue needs an access token in the `TERRATEAM_DRIFT_ACCESS_TOKEN` CI/CD variable.

### Require reviews before apply

Set [apply requirements](/docs/reference/orchestration/configuration/apply-requirements) for production:

```yaml
apply_requirements:
  checks:
    - tag_query: 'dir:production'
      approved:
        enabled: true
        any_of_count: 2
      merge_conflicts:
        enabled: true
      status_checks:
        enabled: true
```

A production apply then needs two approvals, no merge conflicts, and all status checks passing.

## Operational practices

- Run each infrastructure change through the pull request flow, so that plans, approvals, and applies are recorded.
- Watch runs for unexpected activity. In the console, **Runs** under **Orchestration** lists each run. The [audit trail](/docs/orchestration/security/audit-trail) queries the history by user, directory, and date. The job logs in GitHub Actions or GitLab CI hold the runner detail.
- Alert on failed runs and drift with [notifications](/docs/reference/orchestration/configuration/notifications) and the audit trail.
- Store secrets as GitHub Actions secrets, GitLab CI/CD variables, or in a secrets manager. Rotate keys and tokens on a schedule.
- Store plan files where access is restricted. See [Plan file storage](/docs/orchestration/security/plan-file-storage).
- Regularly review who can plan, apply, unlock, and change the configuration, and give each role the least privilege that it needs. Review your configuration and workflows when the organization changes.

## In this section

- [Cloud credentials](/docs/orchestration/security/cloud-credentials): OIDC, static credentials, and credential scripts.
- [Hardening AWS OIDC](/docs/orchestration/security/hardening-aws-oidc): trust policies that only Orchestration-dispatched runs can satisfy.
- [GitHub Environments](/docs/orchestration/security/github-environments): bind workflows to environment-scoped secrets.
- [Private runners](/docs/orchestration/security/private-runners): run plans and applies on your own infrastructure.
- [Plan file storage](/docs/orchestration/security/plan-file-storage): where reviewed plan files live between plan and apply.
- [Self-signed certificates](/docs/orchestration/security/self-signed-certificates): trust internal certificate authorities.
- [Audit trail](/docs/orchestration/security/audit-trail): query the history of runs and state transactions.
- [Security scanning](/docs/infrastructure-as-a-database/security): findings at plan time and posture over time.

Governance:

- [RBAC](/docs/orchestration/governance/rbac)
- [Gatekeeper](/docs/orchestration/governance/gatekeeper)
- [Drift detection](/docs/orchestration/governance/drift-detection)
- [Centralized configuration](/docs/orchestration/governance/centralized-config)
- [Configuration overrides](/docs/orchestration/governance/config-overrides)

Console access:

- [Access control](/docs/admin/access-control): authentication, tenants, access tokens, and group rules for the console and API.
