---
title: Cost Estimation in Pull Requests
description: Stategraph Orchestration adds an Infracost estimate to every plan comment, showing the monthly cost change of a pull request before it is applied.
order: 8
---


Stategraph Orchestration shows the monthly cost change of each pull request in the plan comment, so reviewers see an expensive change before it is applied. Each plan computes an [Infracost](https://www.infracost.io/) diff between the base branch and the pull request. The estimate needs no state in Stategraph, and every Orchestration edition has it.

## Enabling Cost Estimation

Cost estimation is on by default. To turn it off, or to change the currency, set `cost_estimation` in `.stategraph/config.yml`:

```yaml
cost_estimation:
  enabled: true
  provider: infracost
  currency: USD
```

- `enabled`: `true` estimates the cost on each plan. `false` skips it.
- `provider`: the estimation provider. The only value is `infracost`.
- `currency`: the ISO 4217 code of the figures. Default `USD`.

For all keys, see the [cost_estimation reference](/docs/reference/orchestration/configuration/cost-estimation).

## How It Works

1. You open a pull request that changes Terraform code.
2. Orchestration runs a plan on your runner. Before the plan, an `infracost_setup` step runs `infracost breakdown` on the base branch and then on the pull request branch, for the directories and workspaces in the run. Then it compares the two results.
3. The plan comment gets a **Cost Estimation** section with the result.
4. You review the estimate with the change. If the cost is too high, change the code. The next plan estimates it again.
5. After the pull request is approved and applied, the real costs start.

The step adds time to each plan. To see how much, see [Performance](/docs/orchestration/workflows/performance).

## What the Comment Shows

The **Cost Estimation** section shows the total monthly difference in the configured currency. It expands to a table with one row per directory and workspace: the previous monthly cost, the new monthly cost, and the difference. The last row is the total.

<figure class="docs-figure" data-vcs="github">
<div class="docs-mock">
<div class="docs-mock-bar"><span class="docs-mock-avatar"><img src="/assets/logo-symbol.svg" alt=""></span><span class="vcs-github docs-mock-author">Stategraph GitHub App</span><span class="vcs-github docs-mock-badge">bot</span><span class="vcs-gitlab docs-mock-author">Access token user</span><span>commented</span><span class="docs-vcs-switch" role="group" aria-label="Provider"><button type="button" data-vcs-set="github" aria-pressed="true">GitHub</button><button type="button" data-vcs-set="gitlab" aria-pressed="false">GitLab</button></span></div><div class="docs-mock-body"><div class="docs-mock-h">Cost Estimation</div><p><strong>Total Monthly Difference: 6.00 USD</strong></p><details open><summary>Expand for cost estimation details</summary><table><thead><tr><th>Dir</th><th>Workspace</th><th class="num">Previous (USD)</th><th class="num">New (USD)</th><th class="num">Diff (USD)</th></tr></thead><tbody><tr><td>prod/volume</td><td>default</td><td class="num">0.00</td><td class="num">6.00</td><td class="num">6.00</td></tr><tr><td></td><td><strong>Total</strong></td><td class="num"><strong>0.00</strong></td><td class="num"><strong>6.00</strong></td><td class="num"><strong>6.00</strong></td></tr></tbody></table></details></div>
</div>
<figcaption>The Cost Estimation section of a plan comment.</figcaption>
</figure>

When Infracost cannot make the estimate, the section shows **Error calculating Cost Estimation** and expands to the Infracost output. This error does not fail the plan.

## Infracost API Key

Infracost gets its prices from a cloud pricing API. The runner reaches it in one of two ways, on GitHub Actions and GitLab CI runners alike:

- Through the Stategraph server. On [Stategraph Cloud](https://app.stategraph.cloud), you need no key: the server has its own Infracost credentials. On a self-hosted deployment, this is off until you set `INFRACOST_PRICING_API_ENDPOINT` and `SELF_HOSTED_INFRACOST_API_KEY` on the server. See [Environment variables](/docs/admin/operations/environment-variables).
- With your own key. When `INFRACOST_API_KEY` is set, the runner uses the public Infracost API directly. Get a free key on the [Infracost website](https://www.infracost.io/), or use your [Infracost Cloud](https://www.infracost.io/docs/infracost_cloud/get_started/) account.

To give the runner your key:

- GitHub: add a repository secret named `INFRACOST_API_KEY`, for example with `gh secret set INFRACOST_API_KEY`.
- GitLab: in the project, open **Settings > CI/CD > Variables**, add a variable with the key `INFRACOST_API_KEY`, and select **Mask variable**.

For both procedures in full, see [Secrets and variables](/docs/orchestration/configuration/variables).

!!! note "What Infracost sees"
    No cloud credentials or secrets are sent to the pricing API, and Infracost makes no changes to your Terraform state or cloud resources.

## Customizing Infracost

The runner reads these environment variables. Set them with an [`env` hook](/docs/reference/orchestration/configuration/hooks), in a [workflow](/docs/reference/orchestration/configuration/workflows), or as GitHub secrets or GitLab CI/CD variables.

| Variable | Description |
|----------|-------------|
| `INFRACOST_API_KEY` | Your Infracost API key. See [Infracost API Key](#infracost-api-key). |
| `INFRACOST_CURRENCY` | An ISO 4217 currency code. Overrides `currency` in `.stategraph/config.yml`. |
| `INFRACOST_CONFIG_FILE` | The path to your own Infracost [config file](https://www.infracost.io/docs/features/config_file/), in place of the file that the runner generates for the directories and workspaces in the run. A relative path starts at the repository root. |

### Custom config file

Set `INFRACOST_CONFIG_FILE` in a pre-plan hook:

```yaml
hooks:
  plan:
    pre:
      - type: env
        name: INFRACOST_CONFIG_FILE
        cmd: ["echo", "infracost.yml"]
```

When the file does not exist on a branch, for example on the base branch for the previous cost, the runner uses the generated file, and the estimate still runs.

## Considerations

- The estimate uses the Terraform plan and list prices, not usage. Actual costs change with usage and prices.
- Infracost supports many cloud providers and resources, but not every resource type. It leaves out unsupported resources, so an estimate can be incomplete.
- Disable cost estimation for [Pulumi](/docs/orchestration/iac-tools/pulumi) repositories.

## Pull Request Estimate and Plan-Time Cost

Orchestration and Infrastructure as a Database each estimate a change, for different questions:

| | Pull request estimate | Plan-time cost |
|---|---|---|
| Produced by | Orchestration, on your CI runner | Infrastructure as a Database, when `stategraph tf plan` submits a plan |
| Shown in | The plan comment | Under the plan diff, `stategraph tx costs`, and the API |
| Granularity | Per directory and workspace, plus a total | Per resource and per state, with provider, type, and tag breakdowns |
| Stored | In the run's results | As `planned` cost snapshots you can query with SQL |
| Requires | Infracost pricing access | Cost analysis enabled on the server and state stored in Stategraph |

Both are list-price estimates with the same pricing model. When Orchestration runs the [`stategraph` engine](/docs/infrastructure-as-a-database/orchestration), you can use both: the comment gives the reviewer the total, and the cost snapshots give attribution and history after the apply.

## Next Steps

- [cost_estimation reference](/docs/reference/orchestration/configuration/cost-estimation): every key and example
- [Plan-Time Cost](/docs/infrastructure-as-a-database/cost/plan-time): the per-resource cost change in Infrastructure as a Database
- [Pull request workflow](/docs/orchestration/workflows): where the plan comment fits in the run
