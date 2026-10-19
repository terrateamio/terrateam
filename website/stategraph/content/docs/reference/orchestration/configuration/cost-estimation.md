---
title: cost_estimation
description: Reference for the cost_estimation key in .stategraph/config.yml. Post Infracost monthly cost changes alongside every plan comment.
order: 6
---


`cost_estimation` adds an Infracost cost estimate to each pull request that Stategraph Orchestration plans. A comment next to the plan output shows the monthly cost change for the dirspace.

## Default Configuration

```yaml
cost_estimation:
  enabled: true
  provider: infracost
  currency: USD
```

## Keys

| Key | Type | Description |
| --- | --- | --- |
| `enabled` | boolean | Turns on cost estimation. Default is `true`, or `false` on a server without an Infracost backend. See [Enable cost estimation](/docs/admin/self-hosting/cost). |
| `provider` | string | The cost estimation provider. The only value is `infracost`. Default is `infracost`. |
| `currency` | string | The currency of the estimate. Default is `USD`. |

## Providers

### Infracost

!!! note "Infracost and your data"
    Orchestration sends no cloud credentials or secrets to the Infracost Cloud Pricing API. Infracost does not change your Terraform state or cloud resources.

#### API Key

With an Infracost API key in a GitHub Actions secret or a GitLab CI/CD variable named `INFRACOST_API_KEY`, Orchestration uses the official Infracost public API endpoint.

##### GitHub

To set your Infracost API key as a GitHub Actions secret:

1. Export your `organization/repo` as an environment variable. For example:

```bash
export REPO="OWNER/REPO"
```

2. Create the GitHub secret:

```bash
gh secret --repo "$REPO" set INFRACOST_API_KEY
```

##### GitLab

To set your Infracost API key as a GitLab CI/CD variable:

1. Open your GitLab project and go to **Settings**, then **CI/CD**, then **Variables**.
2. Click **Add variable**.
3. Enter the **Key** `INFRACOST_API_KEY` and paste your Infracost API key as the **Value**.
4. Mark the variable as masked, and leave **Protect variable** cleared.
5. Click **Add variable**.

GitLab passes protected variables only to pipelines on protected branches, and Orchestration runs plans on the source branch of the merge request. To share the key across projects, add the variable to the GitLab group.

#### Environment Variables

| Name | Description |
| --- | --- |
| `INFRACOST_API_KEY` | Your Infracost API key. To get a free key, [sign up](https://www.infracost.io/) and open the `Org Settings` page. |
| `INFRACOST_CURRENCY` | An [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217#Active_codes) currency code for the results. It takes precedence over `currency` in the repository configuration. |
| `INFRACOST_CONFIG_FILE` | The path to your own Infracost [config file](https://www.infracost.io/docs/features/config_file/), in place of the one that Orchestration generates. See [Use a Custom Infracost Config File](#use-a-custom-infracost-config-file). |

## Examples

### Enable Cost Estimation with Default Settings

```yaml
cost_estimation:
  enabled: true
```

### Disable Cost Estimation

```yaml
cost_estimation:
  enabled: false
```

### Specify a Different Currency

This reports the results in euros:

```yaml
cost_estimation:
  enabled: true
  currency: EUR
```

### Use a Custom Infracost Config File

By default, Orchestration generates an Infracost config file with the directories and workspaces of the run. To use your own file, set `INFRACOST_CONFIG_FILE` to its path, for example with an [`env` hook](/docs/reference/orchestration/configuration/hooks):

```yaml
hooks:
  plan:
    pre:
      - type: env
        name: INFRACOST_CONFIG_FILE
        cmd: ["echo", "infracost.yml"]
```

The path is absolute, or relative to the repository root. If the file does not exist on a branch, Orchestration uses the file that it generates. An example is the base branch, where Orchestration computes the previous cost.

## Related

- [Cost estimation in pull requests](/docs/orchestration/external-tools/infracost)
- [hooks](/docs/reference/orchestration/configuration/hooks)
