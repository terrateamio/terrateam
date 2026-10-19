---
title: hooks
description: Reference for the hooks key in .stategraph/config.yml. Run commands, set environment variables, and open OIDC sessions before and after runs.
order: 14
---


`hooks` runs commands, sets environment variables, creates gates, and opens OIDC sessions before (pre-hooks) and after (post-hooks) the workflow steps of a Stategraph Orchestration operation. Each hook runs one time per operation. Commands run from the repository checkout directory `$TERRATEAM_ROOT`.

## Default Configuration

```yaml
hooks:
  all:
    pre: []
    post: []
  plan:
    pre: []
    post: []
  apply:
    pre: []
    post: []
```

## Keys

| Key | Type | Description |
| --- | --- | --- |
| `all` | object | Pre and post hooks for all operations. |
| `plan` | object | Pre and post hooks for plan operations. |
| `apply` | object | Pre and post hooks for apply operations. |

In each list, the hooks run in the order that you define them.

## Hook Types

### `env`

The `env` hook type sets environment variables for the operation. It sets one variable from the output of a command, or it sources a script.

#### Command

| Key | Type | Description |
| --- | --- | --- |
| `name` | string | Name of the environment variable. |
| `cmd` | list | Command whose output sets the environment variable. |
| `trim_trailing_newlines` | boolean | Trim trailing newlines. Default is `true`. |
| `sensitive` | boolean | `true` masks the value in the output that Orchestration posts. On GitHub Actions, it is also masked in the job log. On GitLab CI, it is not. Default is `false`. |

#### Source Method

| Key | Type | Description |
| --- | --- | --- |
| `method` | string | Must be set to `source`. |
| `cmd` | list | Command or script that exports environment variables. |
| `sensitive` | boolean | `true` masks the environment variables that the script changes in the output that Orchestration posts. On GitHub Actions, they are also masked in the job log. On GitLab CI, they are not. Default is `false`. |

### `run`

The `run` hook type runs a command. Orchestration records the output of the command, with secrets masked as `***`.

| Key | Type | Description |
| --- | --- | --- |
| `cmd` | list | Command to run. |
| `run_on` | string | Runs the command depending on the state of the workflow: `success`, `failure`, or `always`. Default is `success`. |
| `env` | object | Environment variables for this command. The keys are the variable names, and each value is a string. |
| `ignore_errors` | boolean | `true` ignores a failure. Default is `false`, or `true` when `on_error` contains a gate. |
| `visible_on` | string | When the output of the command shows in a pull request comment or the console: `always`, `failure`, or `success`. Default is `failure`. |
| `log_output` | boolean | `false` keeps the output of the command out of the CI job log. Orchestration still records it. Default is `true`. |
| `format` | string or object | How the output shows in pull request comments: `code` (default, a fenced code block), `raw` (as-is), or `markdown`. The object form `{ type: code, lang: <language> }` gives a fenced code block with syntax highlighting for `<language>`. |
| `on_error` | list | Actions for a failed command. Each entry is an object with a `type`. The only supported type is `gate`, which creates a [Gatekeeper](/docs/orchestration/governance/gatekeeper) gate with the keys `token`, `name`, `all_of`, `any_of`, and `any_of_count`. |

### `gates`

The `gates` hook type runs a command and creates a [Gatekeeper](/docs/orchestration/governance/gatekeeper) gate for each entry of the `gates` list in the JSON that the command prints to standard output. The hook never fails the operation.

| Key | Type | Description |
| --- | --- | --- |
| `cmd` | list | Command to run. Its standard output must be a JSON object of the form `{"gates": [ ... ]}`. Each gate accepts `token`, `name`, `all_of`, `any_of`, `any_of_count`, and `add_reviewers`. |
| `run_on` | string | Runs the command depending on the state of the workflow: `success`, `failure`, or `always`. Default is `success`. |

### `drift_create_issue`

The `drift_create_issue` hook type creates an issue in the repository when a [drift detection](/docs/reference/orchestration/configuration/drift) run finds drift. It works only as a `plan` post-hook of a drift run, and does nothing in other runs. It runs whether the workflow succeeds or fails.

On GitLab, the hook needs an access token in the `TERRATEAM_DRIFT_ACCESS_TOKEN` CI/CD variable. See [drift issues](/docs/reference/orchestration/configuration/drift#issues).

| Key | Type | Description |
| --- | --- | --- |
| `group_by` | string | `all` creates one issue that lists every directory and workspace with drift. `dirspace` creates one issue per directory and workspace. Default is `all`. |

### `oidc`

The `oidc` hook type (`type: oidc`) opens an OIDC connection to a cloud provider.

| Key | Type | Provider | Description |
| --- | --- | --- | --- |
| `provider` | string | | `aws`, `azure`, or `gcp`. Required for `azure` and `gcp`. Default is `aws`. |
| `role_arn` | string | aws | The ARN of the IAM role to use. Can be a GitHub secret or environment variable. |
| `assume_role_arn` | string | aws | The ARN of an IAM role to assume with the credentials of `role_arn`. Without it, the hook uses `role_arn`. Can be a GitHub secret or environment variable. |
| `assume_role_enabled` | boolean | aws | `false` does not assume `assume_role_arn`. The hook still sets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_SESSION_TOKEN` with the credentials of `role_arn`. Default is `true`. |
| `audience` | string | aws | The AWS audience name. Default is `sts.amazonaws.com`. Can be a GitHub secret or environment variable. |
| `region` | string | aws | The AWS region. Sets the `AWS_REGION` environment variable. Default is `us-east-1`. |
| `session_name` | string | aws | The AWS session name. Default is `terrateam`. |
| `duration` | integer | aws | The AWS session duration in seconds. Default is `3600`. |
| `service_account` | string | gcp | Email address or unique identifier of the Google Cloud service account to generate credentials for. Can be a GitHub secret or environment variable. |
| `workload_identity_provider` | string | gcp | The full identifier of the Workload Identity Provider, with the project number, pool name, and provider name. Can be a GitHub secret or environment variable. |
| `access_token_lifetime` | integer | gcp | Lifetime of the access token, in seconds. Default is `3600`. |
| `audience` | string | gcp | The GCP audience name. Default is `https://iam.googleapis.com/` followed by `workload_identity_provider`. |
| `access_token_subject` | string | gcp | Email address of a user to impersonate for [Domain-Wide Delegation](https://developers.google.com/workspace/guides/create-credentials). Can be a GitHub secret or environment variable. |
| `client_id` | string | azure | App Registration client ID. Can be a GitHub secret or environment variable. |
| `tenant_id` | string | azure | Azure AD (Entra ID) tenant ID. Can be a GitHub secret or environment variable. |
| `subscription_id` | string | azure | Default Azure subscription ID. Can be a GitHub secret or environment variable. |
| `audience` | string | azure | The Azure audience name. Default is `api://AzureADTokenExchange`. |

## Examples

### Setting Environment Variables

```yaml
hooks:
  plan:
    pre:
      - type: env
        name: TF_VAR_example
        cmd: ['echo', 'example_value']
```

This pre-hook of the `plan` operation sets `TF_VAR_example` to `example_value`.

### Running Scripts

```yaml
hooks:
  apply:
    post:
      - type: run
        cmd: ['./cleanup_script.sh']
        run_on: always
```

This post-hook of the `apply` operation runs `cleanup_script.sh`, whether the operation succeeds or fails (`run_on: always`).

### AWS OIDC Authentication

```yaml
hooks:
  all:
    pre:
      - type: oidc
        provider: aws
        role_arn: ${AWS_ROLE_ARN}
```

This pre-hook of all operations opens an OIDC connection to AWS with the role ARN in the `AWS_ROLE_ARN` environment variable.

### GCP OIDC Authentication

```yaml
hooks:
  all:
    pre:
      - type: oidc
        provider: gcp
        service_account: ${GCP_SERVICE_ACCOUNT}
        workload_identity_provider: ${GCP_WORKLOAD_IDENTITY_PROVIDER}
```

This pre-hook of all operations opens an OIDC connection to GCP with the service account and workload identity provider in the `GCP_SERVICE_ACCOUNT` and `GCP_WORKLOAD_IDENTITY_PROVIDER` environment variables.

### Azure OIDC Authentication

```yaml
hooks:
  all:
    pre:
      - type: oidc
        provider: azure
        client_id: ${ARM_CLIENT_ID}
        tenant_id: ${ARM_TENANT_ID}
        subscription_id: ${ARM_SUBSCRIPTION_ID}
```

This pre-hook of all operations opens an OIDC connection to Azure with the client ID, tenant ID, and subscription ID in the matching environment variables.

### Creating an Issue on Drift

```yaml
hooks:
  plan:
    post:
      - type: drift_create_issue
        group_by: dirspace
```

When a drift detection run finds changes, this post-hook of the `plan` operation creates one issue per directory and workspace with drift.

## Considerations

- Hooks can add much time to your operations, for example with long-running commands or scripts.
- Hooks can change files in the repository checkout directory (`$TERRATEAM_ROOT`). Test your hooks, so that they do not change or delete important files.
- The command or script of a `run` hook must be available and executable on the runner. Use absolute paths, or install the dependencies.
- The output of a `run` hook can show sensitive information in the pull request comment when the command fails. Sanitize or mask sensitive data in the output.
- Values that an `env` hook sets can show in the logs, and other hooks and workflow steps can read them. Do not put sensitive values directly in the hook configuration. Use GitHub secrets, GitLab CI/CD variables, or another secure method.

## Related

- [workflows](/docs/reference/orchestration/configuration/workflows)
- [Custom commands](/docs/orchestration/workflows/advanced/custom-commands)
- [Cloud credentials](/docs/orchestration/security/cloud-credentials)
- [Gatekeeper](/docs/orchestration/governance/gatekeeper)
