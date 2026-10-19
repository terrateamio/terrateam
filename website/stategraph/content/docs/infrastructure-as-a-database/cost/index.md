---
title: Cost intelligence
description: See what your Terraform state costs per resource, state, and tenant, see the cost delta of a plan, and compare the estimates with billed spend.
order: 1
---


Stategraph estimates the cost of the infrastructure in your Terraform state, per resource, per state, and for your tenant. It also prices a plan before you apply it, and compares the estimates with your billed spend.

An estimate of one configuration cannot show what a full environment costs. Infrastructure as a Database holds the state of record for all of your infrastructure, so Stategraph shows what each environment costs, who owns the spend, and how it trends.

Stategraph Orchestration adds a separate estimate to each pull request: an Infracost delta in the plan comment. See [Cost Estimation in Pull Requests](/docs/orchestration/external-tools/infracost).

## Features

- [State and resource cost](/docs/infrastructure-as-a-database/cost/state-cost): one state, per resource and per component.
- [Plan-time cost](/docs/infrastructure-as-a-database/cost/plan-time): the cost delta of a change at `stategraph tf plan`, before you apply it.
- [Cost attribution](/docs/infrastructure-as-a-database/cost/attribution): cost by provider, resource type, and tag (owner, team, environment) across all managed states, over time.
- [Cloud billing (FOCUS)](/docs/infrastructure-as-a-database/cost/billing-sources): actual cloud spend from a FOCUS billing export, attributed to managed resources.
- [Querying cost data](/docs/infrastructure-as-a-database/cost/queries): SQL over cost snapshots.
- [Cost in the console](/docs/infrastructure-as-a-database/cost/console): tenant overview, explorer, per-state analysis, and billing connections.

## How it works

Stategraph prices each resource from a price book of cloud pricing data. Each estimate is a cost snapshot:

- Per-state totals: cost, coverage, and currency.
- Per resource: monthly and hourly cost, pricing components, and tags.

Stategraph writes a snapshot when you import a state, after an apply or commit, on a schedule (daily by default), and on demand. Each snapshot records its trigger.

Money values are strings, to keep sub-cent precision. Parse them as decimals, not floats. A money field is absent when nothing in its scope has a price.

## Enable and verify

On a self-hosted server, cost analysis is off until you set `STATEGRAPH_COST_ENABLED=true` on the Stategraph server. [Enable cost estimation](/docs/admin/self-hosting/cost) covers the variables, the price book load, and air-gapped installs.

The CLI examples in this section read the server URL from `STATEGRAPH_API_BASE` and the API key from `STATEGRAPH_API_KEY`. See [CLI Reference](/docs/cli).

1. Check that the server has cost analysis on:

```bash
curl -H "Authorization: Bearer $STATEGRAPH_API_KEY" \
  "$STATEGRAPH_API_BASE/api/v1/capabilities"
```

```json
{ "costs": { "enabled": true } }
```

If `enabled` is `false`, the server started without cost analysis, and `POST .../costs/calculate` returns `503`. When you first turn it on, the price book loads in the background, and cost figures appear a few minutes later.

2. Calculate the first estimate for a state, or wait for the next scheduled run:

```bash
stategraph cost calculate --state <state-id>
```

### Where cost appears

With cost analysis on:

- Console: the **Costs** section, and a cost link on each state in the states list and on the state detail page.
- CLI: the `stategraph cost` commands, a `Costs:` block under each `stategraph tf plan`, and `stategraph tx costs` for the delta of a transaction. See [Cost Commands](/docs/cli/cost).
- API: endpoints under `/api/v1/states/{state_id}/costs`, `/api/v1/tenants/{tenant_id}/costs`, and `/api/v1/tx/{tx_id}/costs`. See [API Reference](/docs/reference/api/cost).
- SQL: the `cost_snapshots` and `cost_snapshot_resources` tables.

## Estimates, not bills

Cost figures are list-price estimates from the type and attributes of each resource (instance class, storage size, region). They do not match your invoice to the cent. Use them to compare options, catch expensive changes, and attribute spend.

To see billed spend next to the estimates, connect a FOCUS billing export on the console **Billing connections** page, or with `stategraph cost billing-source add`. The administrators of each tenant manage its billing sources. See [Cloud billing (FOCUS)](/docs/infrastructure-as-a-database/cost/billing-sources).

## Coverage

Each resource in a snapshot has one of three pricing statuses:

| Status | Meaning |
|--------|---------|
| Priced | Supported, and a cost was found. It counts in the totals. |
| `no_price` | Recognized, but nothing is billable (for example, an `aws_db_subnet_group`) |
| Unsupported | No pricing model exists for the type |

`coverage_percent` is the share of resources that have a price. Only priced resources count in the totals, so read each total with its coverage. To list the gaps, use the [unsupported endpoint](/docs/infrastructure-as-a-database/cost/state-cost#coverage-gaps).
