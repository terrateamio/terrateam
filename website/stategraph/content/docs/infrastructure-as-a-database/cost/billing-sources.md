---
title: Cloud billing (FOCUS)
description: Connect a FOCUS billing export from AWS, GCP, or Azure to load your actual cloud spend, then read the attributed and unmanaged spend.
order: 5
---


A billing source loads your actual cloud spend from a billing export in [FOCUS](https://focus.finops.org/), an open format that AWS, GCP, and Azure can all emit. Stategraph syncs and stores it on a schedule, and the console cost pages show it next to the estimates.

Tenant administrators manage billing sources, on the console **Billing connections** page or with the CLI. An installation admin can do so for any tenant. See [Tenants](/docs/admin/access-control/tenants).

## Connect a billing source

1. Create a FOCUS export in your cloud provider. See [Provider Setup](#provider-setup).
2. Point a Stategraph billing source at the exported files:

```bash
stategraph cost billing-source add \
  --tenant <tenant-id> \
  --provider aws \
  --source-uri "s3://my-bucket/focus/data/**/*.parquet"
```

```json
{
  "id": "aef4bd07-…",
  "tenant_id": "…",
  "provider": "aws",
  "source_uri": "s3://my-bucket/focus/data/**/*.parquet",
  "region": "us-east-1",
  "window_months": 2,
  "enabled": true,
  "created_at": "2026-06-09T12:01:17Z",
  "updated_at": "2026-06-09T12:01:17Z"
}
```

An enabled source syncs on a schedule. To sync now, use [`sync`](#manage-sources). Credentials come from the environment (instance role, workload identity, `az login`, or the standard provider variables), so you give no secrets to Stategraph.

| Option for `add` | Required | Description |
|--------|----------|-------------|
| `--provider` | Yes | `aws`, `gcp`, or `azure` |
| `--source-uri` | Yes | Location of the exported files (Parquet or CSV, globs allowed) |
| `--region` | No | Bucket region (AWS). Omit to resolve it from the environment. |
| `--window-months` | No | Trailing months reloaded on each sync. Default `2`: current plus previous. |
| `--disabled` | No | Create the source with scheduled sync off |

## Provider setup

Use the location of the export as `--source-uri`. The first files usually arrive within about 24 hours, then refresh daily.

### AWS

In **Billing and Cost Management** > **Data Exports**, create a FOCUS 1.0 standard export (Parquet) to an S3 bucket.

- `--source-uri`: `s3://bucket/prefix/<export>/data/**/*.parquet`
- [Create a data export](https://docs.aws.amazon.com/cur/latest/userguide/dataexports-create-standard.html) and [FOCUS 1.0 columns](https://docs.aws.amazon.com/cur/latest/userguide/table-dictionary-focus-1-0-aws.html)

### GCP

Turn on detailed billing export to BigQuery, then export the FOCUS view to a GCS bucket (Parquet or CSV).

- `--source-uri`: `gs://bucket/prefix/**/*.parquet`
- [Set up billing export](https://cloud.google.com/billing/docs/how-to/export-data-bigquery-setup) and [FOCUS billing view](https://cloud.google.com/blog/topics/cost-management/new-bigquery-cloud-billing-view-based-on-focus)

### Azure

In **Cost Management** > **Exports**, create an export with the Cost and usage details (FOCUS) dataset (Parquet) to a storage account.

- `--source-uri`: `abfss://container@account.dfs.core.windows.net/path/**/*.parquet`
- [Create an export](https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-improved-exports) and [FOCUS schema](https://learn.microsoft.com/en-us/azure/cost-management-billing/dataset-schema/cost-usage-details-focus)

## Manage sources

List sources:

```bash
stategraph cost billing-source list --tenant <tenant-id>
```

Sync now. `--from` backfills from a date instead of the trailing window:

```bash
stategraph cost billing-source sync --tenant <tenant-id> <source-id> --from 2026-01-01
```

Change settings. Omitted fields do not change:

```bash
stategraph cost billing-source update --tenant <tenant-id> <source-id> --window-months 3
```

Pause or resume scheduled sync:

```bash
stategraph cost billing-source disable --tenant <tenant-id> <source-id>
stategraph cost billing-source enable --tenant <tenant-id> <source-id>
```

Remove a source and the billing rows that it loaded:

```bash
stategraph cost billing-source remove --tenant <tenant-id> <source-id>
```

- `list` shows `last_status`, `last_synced_at`, and `last_row_count` for each source, to confirm that syncs land.
- `update` also accepts `--source-uri`, `--region`, and `--enabled=true|false`.
- `remove` asks for confirmation. `--auto-approve` skips the prompt.

## Read actual spend

After each sync, Stategraph attributes the billed spend to managed infrastructure, per tenant and per state. Any tenant member can read it:

```
GET /api/v1/tenants/{tenant_id}/costs/attribution   # billed spend attributed to managed resources, by provider
GET /api/v1/tenants/{tenant_id}/costs/unmanaged      # billed resources no state manages
GET /api/v1/states/{state_id}/costs/actuals          # billed spend attributed to one state, per resource
```

`cost attribution` shows how much billed spend Stategraph matched to managed resources:

```bash
stategraph cost attribution --tenant <tenant-id>
```

| Field | Meaning |
|-------|---------|
| `total_cost` | Total billed spend in the window |
| `attributed_cost` | Spend matched to a managed resource |
| `unallocated_cost` | Spend that matched no managed resource |
| `unmanaged_cost` | Spend for resources that no state manages |
| `coverage_percent` | Share of spend that was attributed |

It also returns `attributed_count`, `unmanaged_count`, `unallocated_count`, `uncomputed_count`, `line_count`, `computed_at`, `matcher_version`, `window_start`, `window_end`, `currency` (absent when the loaded billing lines mix currencies), and a `by_provider` breakdown with the same fields per provider.

`cost unmanaged` lists the billed resources that no state manages, to find spend outside Terraform:

```bash
stategraph cost unmanaged --tenant <tenant-id> --limit 20
```

Each entry in `results[]` has `provider`, `service_name`, `resource_id`, `resource_type`, `region_id`, `billed_cost`, `line_count`, and `currency`. Both commands accept `--format=table|json|simple`.

Per-state actuals are API only. The response covers the loaded billing window:

- `billed_cost` and `line_count` of the state.
- `resources[]`: `address`, `billed_cost`, and `line_count` of each resource.
- `currency`, `computed_at`, `window_start`, and `window_end`, when attribution has run.

A state with no attributed spend returns an empty breakdown.

```bash
curl -H "Authorization: Bearer $STATEGRAPH_API_KEY" \
  "$STATEGRAPH_API_BASE/api/v1/states/$STATE_ID/costs/actuals"
```

The console **Analysis** page of a state compares the actual run rate with the estimate. See [Cost in the console](/docs/infrastructure-as-a-database/cost/console).

## API

The CLI wraps these admin endpoints. A non-admin caller gets `403`.

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/tenants/{tenant_id}/billing-sources` | List sources |
| `POST` | `/api/v1/tenants/{tenant_id}/billing-sources` | Create a source |
| `PUT` | `/api/v1/tenants/{tenant_id}/billing-sources/{id}` | Update a source |
| `POST` | `/api/v1/tenants/{tenant_id}/billing-sources/{id}/sync` | Trigger a sync |
| `DELETE` | `/api/v1/tenants/{tenant_id}/billing-sources/{id}` | Delete a source |

## Next steps

- [Cost intelligence](/docs/infrastructure-as-a-database/cost): cost estimates.
- [Cost attribution](/docs/infrastructure-as-a-database/cost/attribution): estimated spend by tag.
- [Cost commands](/docs/cli/cost): all `stategraph cost` commands.
