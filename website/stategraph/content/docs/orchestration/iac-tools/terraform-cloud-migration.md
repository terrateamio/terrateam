---
title: Migrating from Terraform Cloud
description: Move workspaces from Terraform Cloud to Stategraph: inventory, state in Infrastructure as a Database or a bucket, secrets, workflows, and validation.
order: 6
---

To move from Terraform Cloud (TFC) to Stategraph, take an inventory, move the state, secrets, and workflows, and validate. TFC is HashiCorp's managed service for remote state, remote execution, and collaboration through a web UI. Stategraph replaces both parts:

- Stategraph Orchestration replaces the run pipeline: plans on pull requests, approvals, and applies, all through GitHub or GitLab.
- Infrastructure as a Database replaces remote state with a graph in PostgreSQL.

You can move both at the same time, or one at a time.

## Pre-migration planning

Take an inventory of your TFC setup:

1. Organizations and workspaces: note the purpose of each workspace (project, environment), and its repository and directory. Record the Terraform version and the important workspace settings.
2. State: TFC keeps state per workspace. Note each workspace name. It becomes the state name in Infrastructure as a Database, or part of the key path in a bucket backend.
3. Variables and secrets: document each workspace variable, sensitive or not.
4. Workflow triggers: find out how runs start today (VCS push, manual in the UI, CLI-driven). To replace TFC run tasks or webhooks, use [hooks](/docs/reference/orchestration/configuration/hooks) and [webhooks](/docs/orchestration/external-tools/webhooks).
5. Compliance and approvals: note whether TFC used Sentinel, manual approvals, or RBAC.
6. State location: import the state into Infrastructure as a Database, or keep a remote backend such as AWS S3 with DynamoDB locking, Azure Blob, or GCS. Orchestration alone does not keep state.
7. Security: decide where secrets go, usually GitHub secrets or GitLab CI/CD variables. Replace TFC team restrictions with GitHub teams or GitLab groups, repository permissions, [CODEOWNERS](/docs/orchestration/configuration/codeowners), and `access_control` in `.stategraph/config.yml`.

Put the answers in a checklist for each workspace, so that you forget nothing, such as an API key.

## Migrating Terraform state

### Into Infrastructure as a Database

Import each workspace one time. Run these commands in the directory of the workspace's root module:

```bash
terraform login
terraform state pull > terraform.tfstate
stategraph import tf --name prod-network --tenant $STATEGRAPH_TENANT_ID --workspace default terraform.tfstate
```

The import writes a `stategraph.json` file next to your configuration. Commit it. Remove the `backend` block from the configuration, because Stategraph keeps the state now. To verify, run `stategraph states summary --state <state-id>`, and a `stategraph plan` that shows no changes.

For prerequisites and the full flow, see [Import your Terraform state](/docs/get-started/quickstart/import-state). A change that reaches dependent workspaces plans and applies as one [multi-state transaction](/docs/infrastructure-as-a-database/multi-state).

### Into a bucket backend

This example uses AWS S3. Adapt it for other backends.

1. Export the state from TFC:

```bash
terraform login
terraform state pull > terraform.tfstate
```

2. Create an S3 bucket, for example `acme-terraform-state`, with versioning and encryption.
3. Update the Terraform backend:

```hcl
terraform {
  backend "s3" {
    bucket         = "acme-terraform-state"
    key            = "prod/network/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

4. Run `terraform init -migrate-state`, and approve the migration.
5. Run `terraform plan`, and make sure that it shows no changes.

Do these steps for each workspace, with a different `key` path.

## Handling secrets and environment variables

The TFC UI shows non-sensitive values. It masks sensitive values and never shows them again. Rotate or regenerate each sensitive value that you did not keep elsewhere. Then store each value where your CI runner reads it.

Orchestration gives these values to plan and apply as environment variables. Terraform reads each variable with the prefix `TF_VAR_` as an input variable. See [Variables](/docs/orchestration/configuration/variables).

- GitHub: use GitHub secrets for credentials, and GitHub variables for non-sensitive configuration. To scope secrets to dev, staging, and production, use [GitHub Environments](/docs/orchestration/security/github-environments).
- GitLab: use CI/CD variables on the project, or on the group to share them across projects. Mask credentials. Keep variables unprotected unless each branch that opens merge requests is protected. See [GitLab variables](/docs/orchestration/configuration/variables#gitlab).
- OIDC: use OIDC in place of static credentials. Orchestration then assumes cloud roles, with no long-lived secrets in your VCS. See [Cloud credentials](/docs/orchestration/security/cloud-credentials) and the guides for [AWS](/docs/orchestration/cloud-providers/aws/oidc), [GCP](/docs/orchestration/cloud-providers/gcp/oidc), and [Azure](/docs/orchestration/cloud-providers/azure/oidc).
- Static secrets: keep the ones that you still need in GitHub secrets, GitLab CI/CD variables, or an external vault.
- Logs: make sure that your Terraform code and scripts do not print sensitive values. Orchestration masks the values of `env` steps with `sensitive: true` in all output.

## Execution and workflow migration

1. Connect the repository: sign in at [app.stategraph.cloud](https://app.stategraph.cloud) and, from **Get Started**, install the GitHub App or connect your GitLab group. Or set up a [self-hosted](/docs/get-started/quickstart) server. See [Stategraph Cloud](/docs/get-started/quickstart/cloud).
2. Mirror your TFC workflows:
    - Automatic plan on pull request: Orchestration comments the plan on the pull request.
    - Manual approvals: in place of TFC's "Confirm & Apply", comment `stategraph apply` on the pull request, or [apply after merge](/docs/orchestration/workflows/apply-after-merge).
    - Multiple environments: replace TFC workspaces with separate directories, tags, or Terraform workspaces in `.stategraph/config.yml`. See [Multi-environment](/docs/orchestration/workflows/advanced/multi-environment).
3. Configure `.stategraph/config.yml`:
    - [engine](/docs/reference/orchestration/configuration/engine) to choose the tool: Terraform (the default), OpenTofu, the `stategraph` CLI, Terragrunt, Pulumi, CDKTF, or a custom command.
    - [dirs](/docs/reference/orchestration/configuration/dirs) for each environment.
    - [apply_requirements](/docs/reference/orchestration/configuration/apply-requirements) to require approvals and passing checks.
    - [access_control](/docs/reference/orchestration/configuration/access-control) to control who can apply in each environment.
4. Test: open a test pull request. Make sure that the plan comment appears and the secrets resolve. Then run a test `stategraph apply`, and make sure that it uses the new state location.

## Compliance, logging, and auditability

Rewrite Sentinel policies in Rego, and run them with the [conftest or opa workflow steps](/docs/orchestration/external-tools/opa), or add [Checkov scanning](/docs/infrastructure-as-a-database/security). Orchestration runs these checks on each pull request, and can hold a failed plan behind a [gate](/docs/orchestration/governance/gatekeeper).

Pull request reviews and branch protection replace TFC's manual apply, and [access control](/docs/reference/orchestration/configuration/access-control) replaces its RBAC. Orchestration can also require specific approvers, teams, or roles through [apply requirements](/docs/reference/orchestration/configuration/apply-requirements).

Each change leaves these records:

- Pull request history: each plan and apply is a comment on the pull request.
- [Audit trail](/docs/orchestration/security/audit-trail): in the console, **Runs** and **Audit** list each Orchestration run. **Audit** exports CSV and JSON.
- CI logs: each run is a job log. Keep it, or export it to a central store.
- With Infrastructure as a Database, each apply is a transaction on the [timeline](/docs/infrastructure-as-a-database/query/timeline).

Orchestration also posts [cost estimates](/docs/orchestration/external-tools/infracost) on pull requests.

## Custom workflows and automation

- Hooks and workflows: run scripts before or after plan and apply, for policy checks, validation, or notifications. See [hooks](/docs/reference/orchestration/configuration/hooks) and [workflows](/docs/reference/orchestration/configuration/workflows).
- Parallel or layered runs: run directories in parallel, or set dependencies so that some directories apply before others. See [Layered runs](/docs/orchestration/workflows/advanced/layered-runs) and [parallel_runs](/docs/reference/orchestration/configuration/parallel-runs).
- Branching strategies: drive multi-environment setups from branch names or tags. See [GitFlow](/docs/orchestration/workflows/advanced/gitflow).
- Notifications: post to Slack or Teams on success or failure. See [notifications](/docs/reference/orchestration/configuration/notifications) and [Webhooks](/docs/orchestration/external-tools/webhooks).
- Monorepo or multiple repositories: keep the repository layout of TFC, or move to one repository with subdirectories.

## Validating the migration

- Test outside production: try dev or staging first, and compare the TFC plan with the Orchestration plan.
- Compare state: run `terraform state list` against a bucket backend, or `stategraph states summary --state <state-id>` in Infrastructure as a Database, and make sure that each resource is there.
- Check drift: if TFC was behind, the first plan can show differences. Review them carefully. Turn on [drift detection](/docs/orchestration/governance/drift-detection) when the migration is stable.

## Final steps

1. Decommission TFC: when each workspace is migrated and validated, disable the workspaces in TFC and cancel the subscription.
2. Train your team: give them a short guide to pull requests, plan output, and `stategraph apply`.
3. Tune the configuration: monitor runs and collect feedback. Refine parallel runs, environment tags, and hooks in `.stategraph/config.yml`, and add OPA policies, validation, or new environments as needed.

## Next Steps

- [Import your Terraform state](/docs/get-started/quickstart/import-state): move state into Infrastructure as a Database
- [Workflows](/docs/orchestration/workflows): how pull requests trigger plans and applies
- [Support](/docs/support): help with a migration
