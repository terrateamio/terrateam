---
title: Cost Commands
description: Use the stategraph cost commands to manage FOCUS billing sources and to query state, tenant, attribution, history, and coverage cost data.
order: 10
---


The `stategraph cost` commands manage FOCUS billing sources and query cost data:

- [FOCUS](https://focus.finops.org/) billing sources load your actual cloud spend from AWS, GCP, or Azure. Only admins manage them, per tenant.
- Read-only [cost queries](#cost-queries) read your computed estimates and billed spend: state and tenant cost, attribution, history, and coverage gaps.

Cost intelligence must be on in the server: see [Enable cost estimation](/docs/admin/self-hosting/cost). The plan-time cost preview is separate: see [Plan-time cost](/docs/infrastructure-as-a-database/cost/plan-time).

## Commands

### Billing sources

| Command | Description |
|---------|-------------|
| `stategraph cost billing-source add` | Add a FOCUS billing source to a tenant |
| `stategraph cost billing-source list` | List the billing sources of a tenant |
| `stategraph cost billing-source update` | Update a billing source. Omitted fields do not change. |
| `stategraph cost billing-source enable` | Resume the scheduled sync of a source |
| `stategraph cost billing-source disable` | Pause the scheduled sync of a source |
| `stategraph cost billing-source sync` | Sync a source now |
| `stategraph cost billing-source remove` | Remove a source and its loaded billing rows |

All billing-source subcommands take `--tenant` (or `STATEGRAPH_TENANT_ID`). All except `add` and `list` take the source ID as a positional argument.

### Cost query commands

| Command | Description |
|---------|-------------|
| `stategraph cost state` | Cost of one state: totals, coverage, and cost per resource |
| `stategraph cost calculate` | Start a new cost calculation for a state |
| `stategraph cost unsupported` | Coverage gaps: resources in a state that Stategraph cannot price |
| `stategraph cost tenant` | Tenant cost: totals, coverage, and cost per state |
| `stategraph cost attribution` | Actual (FOCUS) spend attributed to managed resources, by provider |
| `stategraph cost history` | Tenant cost over time, one point per day |
| `stategraph cost tag-keys` | Tag keys available for cost attribution in a tenant |
| `stategraph cost unmanaged` | Billed resources that the states of the tenant do not manage |

## stategraph cost billing-source add

Set `--source-uri` to the exported files, in Parquet or CSV. Globs are allowed. Credentials come from the environment (instance role, workload identity, `az login`, or the standard provider environment variables), so you give no secrets to Stategraph.

```bash
stategraph cost billing-source add \
  --tenant <tenant-id> \
  --provider aws \
  --source-uri "s3://my-bucket/focus/data/**/*.parquet"
```

### Options

| Option | Required | Description |
|--------|----------|-------------|
| `--tenant` | Yes | Tenant ID (UUID) |
| `--provider` | Yes | Cloud provider: `aws`, `gcp`, or `azure` |
| `--source-uri` | Yes | FOCUS export location. See the table below. |
| `--region` | No | Bucket region (AWS). Without it, the region comes from the environment. |
| `--window-months` | No | Trailing reload window in months. Default: `2`, the current and previous month. |
| `--disabled` | No | Create the source disabled. It does not sync on schedule until you enable it. |

The `--source-uri` shape for each provider:

| Provider | `--source-uri` |
|----------|----------------|
| AWS | `s3://bucket/prefix/<export>/data/**/*.parquet` |
| GCP | `gs://bucket/prefix/**/*.parquet` |
| Azure | `abfss://container@account.dfs.core.windows.net/path/**/*.parquet` |

Output (JSON):

```json
{
  "id": "2d5013c1-57c6-47d2-8e99-c988d6ecb1c8",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "provider": "aws",
  "source_uri": "s3://my-bucket/focus/data/**/*.parquet",
  "region": "us-east-1",
  "window_months": 2,
  "enabled": true,
  "created_at": "2026-06-11T12:47:32Z",
  "updated_at": "2026-06-11T12:47:32Z"
}
```

## stategraph cost billing-source list

```bash
stategraph cost billing-source list --tenant <tenant-id>
```

Output (table):

```text
id            provider  source_uri                            region     window_months  enabled  last_status  last_synced_at        last_row_count
------------  --------  ------------------------------------  ---------  -------------  -------  -----------  --------------------  --------------
2d5013c1-...  aws       s3://my-bucket/focus/data/**/*.par...  us-east-1  2              true     ok           2026-06-11T03:10:02Z  184022
```

`last_status`, `last_synced_at`, and `last_row_count` show the sync health of each source. For the structured form, use `--format json`.

## stategraph cost billing-source update

```bash
stategraph cost billing-source update --tenant <tenant-id> [options] <source-id>
```

### Options

| Option | Required | Description |
|--------|----------|-------------|
| `--tenant` | Yes | Tenant ID (UUID) |
| `--source-uri` | No | New FOCUS export location |
| `--region` | No | New bucket region |
| `--window-months` | No | New trailing reload window in months |
| `--enabled` | No | Enable (`true`) or disable (`false`) the source |

### Example

```bash
stategraph cost billing-source update --tenant <tenant-id> --window-months 3 <source-id>
```

## stategraph cost billing-source enable / disable

Both commands print the updated source as JSON.

```bash
stategraph cost billing-source disable --tenant <tenant-id> <source-id>
stategraph cost billing-source enable  --tenant <tenant-id> <source-id>
```

## stategraph cost billing-source sync

Syncs without waiting for the schedule.

```bash
stategraph cost billing-source sync --tenant <tenant-id> [--from <date>] <source-id>
```

### Options

| Option | Required | Description |
|--------|----------|-------------|
| `--tenant` | Yes | Tenant ID (UUID) |
| `--from` | No | Backfill from this date (`YYYY-MM-DD`), in place of the trailing window |

### Example

```bash
# Backfill the year to date
stategraph cost billing-source sync --tenant <tenant-id> --from 2026-01-01 <source-id>
```

## stategraph cost billing-source remove

The command asks for confirmation. In scripts, add `--auto-approve` to skip the prompt.

```bash
stategraph cost billing-source remove --tenant <tenant-id> [--auto-approve] <source-id>
```

Output:

```text
Billing source 2d5013c1-57c6-47d2-8e99-c988d6ecb1c8 deleted
```

## Cost queries

Each cost query takes `--api-base` (or `STATEGRAPH_API_BASE`). All except `calculate` accept `--format=table|json|simple` (default `table`).

| Scope | Commands | Required option |
|-------|----------|-----------------|
| Tenant | `attribution`, `history`, `tag-keys`, `tenant`, `unmanaged` | `--tenant` (or `STATEGRAPH_TENANT_ID`) |
| State | `state`, `calculate`, `unsupported` | `--state`, a UUID, with no environment variable. These commands do not accept `--tenant`. |

## stategraph cost state

Uses the latest snapshot of the state. For the fields, see [State and resource cost](/docs/infrastructure-as-a-database/cost/state-cost).

```bash
stategraph cost state --state <state-id>
```

## stategraph cost calculate

Enqueues a recompute and returns a task. The recompute runs in the background, and a new snapshot lands when it finishes.

```bash
stategraph cost calculate --state <state-id>
```

## stategraph cost unsupported

```bash
stategraph cost unsupported --state <state-id>
```

## stategraph cost tenant

With `--tag-key`, the rollup breaks down by the values of that tag, not by state.

```bash
stategraph cost tenant --tenant <tenant-id> [--tag-key Team]
```

## stategraph cost attribution

Requires a connected [billing source](/docs/infrastructure-as-a-database/cost/billing-sources).

```bash
stategraph cost attribution --tenant <tenant-id>
```

## stategraph cost history

The points are oldest first.

| Option | Required | Description |
|--------|----------|-------------|
| `--from` | No | History window start (ISO 8601). Default: 30 days ago. |
| `--to` | No | History window end (ISO 8601). Default: now. |
| `--group-by` | No | Group each point by `provider`, `type`, or `tag` (with `--tag-key`) |
| `--tag-key` | No | Tag key for `--group-by tag` |

```bash
stategraph cost history --tenant <tenant-id> --group-by provider
```

## stategraph cost tag-keys

The keys are Terraform tag keys.

```bash
stategraph cost tag-keys --tenant <tenant-id>
```

## stategraph cost unmanaged

`--limit` sets the maximum number of entries.

```bash
stategraph cost unmanaged --tenant <tenant-id> [--limit 20]
```

## Next steps

- [Cloud billing (FOCUS)](/docs/infrastructure-as-a-database/cost/billing-sources): provider export setup and the full workflow.
- [Cost](/docs/infrastructure-as-a-database/cost): estimate-based cost.
- [Plan-time cost](/docs/infrastructure-as-a-database/cost/plan-time): cost deltas in `stategraph tf plan`.
- [Enable cost estimation](/docs/admin/self-hosting/cost): cost estimation on a self-hosted server.
