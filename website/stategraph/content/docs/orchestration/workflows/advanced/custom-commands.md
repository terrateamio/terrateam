---
title: Custom Plan and Apply Steps
description: Extend plan and apply workflows with run, env, and oidc steps to add validation, security scanning, and notifications around Terraform operations.
order: 5
---


Custom steps add your own commands to a Stategraph Orchestration workflow, around the engine steps `init`, `plan`, and `apply`. A custom step runs a script, sets an environment variable, or authenticates to a cloud provider. Use custom steps to:

- Run checks before an apply.
- Run security and compliance scans.
- Notify monitoring or messaging systems.

## Configuring custom steps

Add the steps to the `plan` and `apply` lists of a workflow in `.stategraph/config.yml`:

```yaml
workflows:
  - tag_query: "dir:prod"
    plan:
      - type: init
      - type: run
        cmd: ['${TERRATEAM_ROOT}/scripts/pre-plan.sh']
      - type: plan
      - type: run
        cmd: ['${TERRATEAM_ROOT}/scripts/post-plan.sh']
    apply:
      - type: init
      - type: run
        cmd: ['${TERRATEAM_ROOT}/scripts/pre-apply.sh']
      - type: apply
      - type: run
        cmd: ['${TERRATEAM_ROOT}/scripts/post-apply.sh']
```

!!! note "What is TERRATEAM_ROOT?"
    `TERRATEAM_ROOT` is the absolute path of the repository checkout on the runner. See [Runner environment variables](/docs/orchestration/configuration/environment-variables) for the full list.

- Steps run in the order that you list them. Put an `env` or `oidc` step before the steps that need it.
- A workflow that sets `plan` steps must include a `plan` step. A workflow that sets `apply` steps must include an `apply` step. A `run` step that calls `terraform plan` does not count.
- A failed custom step stops the workflow by default, and Orchestration posts the error on the pull request. To continue after a failure, set `ignore_errors: true` on the step.

## Step types

Workflows accept the step types `init`, `plan`, `apply`, `run`, `env`, `oidc`, `checkov`, `conftest`, `opa`, and `gates`, in both the `plan` and the `apply` list. The [workflows reference](/docs/reference/orchestration/configuration/workflows) lists every key of every type.

### Run

The `run` step runs a command or script in the directory of the operation. `cmd` is the command, as a list of strings.

```yaml
- type: run
  cmd: ['${TERRATEAM_ROOT}/scripts/my-script.sh']
```

Other options include `run_on` (run only on `success`, `failure`, or `always`), `ignore_errors`, `capture_output`, `visible_on`, and `format`. See the [run step options](/docs/reference/orchestration/configuration/workflows).

### Env

The `env` step sets an environment variable for the steps that follow it. `name` is the variable, and the output of `cmd` is the value.

```yaml
- type: env
  name: MY_VAR
  cmd: ['echo', 'my-value']
```

`sensitive: true` keeps the value out of the step's log and masks it in the output that Orchestration posts. To export several variables from one script, use `method: source`. See the [env step options](/docs/reference/orchestration/configuration/workflows).

### OIDC

The `oidc` step authenticates to AWS, GCP, or Azure with OpenID Connect.

#### AWS

```yaml
- type: oidc
  provider: aws
  role_arn: arn:aws:iam::123456789012:role/terraform-role
  region: us-west-2
```

#### GCP

```yaml
- type: oidc
  provider: gcp
  project_id: your-project-id
  workload_identity_provider: projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider
  service_account: my-service-account@my-project.iam.gserviceaccount.com
```

See the [OIDC step options](/docs/reference/orchestration/configuration/workflows) and the [cloud provider guides](/docs/orchestration/cloud-providers/aws/oidc).

## Example workflow

With the configuration in [Configuring custom steps](#configuring-custom-steps):

1. Open a pull request that changes Terraform files in the `prod` directory.
2. Orchestration runs the plan steps: `init`, `pre-plan.sh`, `plan`, and `post-plan.sh`.
3. Review the plan with your team.
4. After approval, comment `stategraph apply`, or merge if `when_modified.autoapply` is `true`. Orchestration runs the apply steps: `init`, `pre-apply.sh`, `apply`, and `post-apply.sh`.
5. Orchestration posts the apply results on the pull request.

## Best practices

- Scripts can read sensitive data. Keep secrets out of logs and captured output.
- Limit custom steps to the directories that need them with [dirs](/docs/reference/orchestration/configuration/dirs) and [tag queries](/docs/orchestration/workflows/advanced/tag-system).
- Use [hooks](/docs/reference/orchestration/configuration/hooks) for commands that run once per operation, not once per directory.
- Pass configuration through environment variables, not hard-coded values.
- Handle errors and write clear logs in each script.
- Document the tools that each script needs.
- Keep each script to one job.
- Keep the scripts in the repository of the infrastructure code.

## Next steps

- [workflows reference](/docs/reference/orchestration/configuration/workflows)
- [hooks reference](/docs/reference/orchestration/configuration/hooks)
- [Runner environment variables](/docs/orchestration/configuration/environment-variables)
