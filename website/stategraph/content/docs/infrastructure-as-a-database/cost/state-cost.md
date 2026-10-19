---
title: State and resource cost
description: Get the cost of one Terraform state, read the cost of each resource and pricing component, refresh the estimate, and find coverage gaps.
order: 3
---


Stategraph prices each Terraform state per resource and per pricing component, and lists the resources that are not in the totals. All cost endpoints require authentication and return money fields as strings.

```
GET  /api/v1/states/{state_id}/costs             # latest snapshot + per-resource breakdown
POST /api/v1/states/{state_id}/costs/calculate   # recompute now
GET  /api/v1/states/{state_id}/costs/unsupported  # resources that didn't contribute (gaps)
GET  /api/v1/states/{state_id}/costs/actuals      # billed FOCUS spend attributed to this state
```

The first three have [CLI commands](/docs/cli/cost): `stategraph cost state`, `stategraph cost calculate`, and `stategraph cost unsupported`. `state` and `unsupported` accept `--format=table|json|simple`. `actuals` reads billed spend from a [FOCUS billing source](/docs/infrastructure-as-a-database/cost/billing-sources#read-actual-spend) and has no CLI command.

## Price a state

Get the latest snapshot:

```bash
stategraph cost state --state $STATE_ID
```

Or with the API:

```bash
curl -H "Authorization: Bearer $STATEGRAPH_API_KEY" \
  "$STATEGRAPH_API_BASE/api/v1/states/$STATE_ID/costs"
```

```json
{
  "snapshot_id": "…",
  "calculated_at": "2026-06-09T06:15:01Z",
  "source": "estimate",
  "triggered_by": "scheduled",
  "currency": "USD",
  "monthly_cost": "1509.640000",
  "hourly_cost": "2.067000",
  "resource_count": 24,
  "supported_count": 24,
  "priced_count": 12,
  "coverage_percent": 50.0,
  "instance_costs": [ … ]
}
```

A `404` means the state was never priced: [calculate it first](#calculate-or-refresh).

| Field | Meaning |
|-------|---------|
| `monthly_cost` / `hourly_cost` | Total estimated cost of the priced resources. A string, absent when nothing is priced. |
| `currency` | For example, `USD` |
| `source` | How Stategraph got the numbers: `estimate` for a list-price quote |
| `triggered_by` | What wrote the snapshot: `state_import`, `tx_apply`, `actuator_commit`, `scheduled`, `manual`, or `preview` |
| `resource_count` | Resources in the state |
| `supported_count` | Resources of a type that Stategraph recognizes |
| `priced_count` | Resources with a non-zero price |
| `coverage_percent` | `priced_count / resource_count`. Read every total with it. |

## Per-resource breakdown

`instance_costs[]` has one entry per resource. Its `components[]` split the price into line items, such as instance hours, storage, and requests. For an `aws_db_instance`:

```json
{
  "address": "aws_db_instance.primary",
  "type": "aws_db_instance",
  "provider": "aws",
  "monthly_cost": "656.270000",
  "hourly_cost": "0.899000",
  "supported": true,
  "no_price": false,
  "components": [
    {
      "name": "Database instance (on-demand, Multi-AZ, db.r6g.xlarge)",
      "unit": "hours",
      "price": "0.8990000000",
      "hourly_quantity": "1",
      "monthly_quantity": "730",
      "hourly_cost": "0.899000",
      "monthly_cost": "656.270000"
    },
    {
      "name": "Storage (general purpose SSD, gp3)",
      "unit": "GB",
      "price": "0.0000000000",
      "monthly_quantity": "200"
    }
  ],
  "tags": { "Team": "data", "Environment": "production", "Project": "acme" },
  "cloud_resource_id": "arn:aws:rds:us-east-1:…:db:acme-primary"
}
```

Each resource also has its `tags`, for [cost attribution](/docs/infrastructure-as-a-database/cost/attribution), and its `cloud_resource_id` when known.

## Calculate or refresh

Snapshots refresh on a schedule and after applies. You need a recompute only when cost data is missing or stale. A recompute returns `202` with a task, runs in the background, and writes a new snapshot. It returns `503` if the server has [cost analysis off](/docs/admin/self-hosting/cost).

1. Start the recompute:

```bash
stategraph cost calculate --state $STATE_ID
```

Or with the API:

```bash
curl -X POST -H "Authorization: Bearer $STATEGRAPH_API_KEY" \
  "$STATEGRAPH_API_BASE/api/v1/states/$STATE_ID/costs/calculate"
```

```json
{ "id": "ca019a18-…", "state": "pending" }
```

2. Poll the task until `completed`. Treat `failed` or `aborted` as an error.

```bash
curl -H "Authorization: Bearer $STATEGRAPH_API_KEY" \
  "$STATEGRAPH_API_BASE/api/v1/tasks/$TASK_ID"
```

```json
{ "id": "ca019a18-…", "state": "completed" }
```

3. Get the cost again.

**Recalculate** on the console **Analysis** page does the same.

## Coverage gaps

List the resources that are not in the totals: unsupported types, and recognized types with nothing billable (`no_price`):

```bash
stategraph cost unsupported --state $STATE_ID
```

Or with the API:

```bash
curl -H "Authorization: Bearer $STATEGRAPH_API_KEY" \
  "$STATEGRAPH_API_BASE/api/v1/states/$STATE_ID/costs/unsupported"
```

```json
{
  "snapshot_id": "…",
  "calculated_at": "2026-06-09T06:15:01Z",
  "resources": [
    { "address": "aws_db_parameter_group.postgres16", "type": "aws_db_parameter_group",
      "provider": "aws", "supported": true, "no_price": true },
    { "address": "aws_db_subnet_group.main", "type": "aws_db_subnet_group",
      "provider": "aws", "supported": true, "no_price": true }
  ]
}
```

Show this list with every total. A high gap count usually means free-to-create resources, such as parameter groups, subnet groups, and IAM, not missing prices.

## Next steps

- [Cost attribution](/docs/infrastructure-as-a-database/cost/attribution): tenant rollups.
- [Querying cost data](/docs/infrastructure-as-a-database/cost/queries): the same data in SQL.
- [Cost in the console](/docs/infrastructure-as-a-database/cost/console): the Analysis page.
