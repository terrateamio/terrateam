---
title: Cost and billing
description: API endpoints for estimated and actual cost per state and tenant, cost history and attribution, plan-time cost, and cloud billing sources.
order: 9
---


These endpoints estimate and read infrastructure costs: per state and per tenant, over time, per transaction plan, and against your actual cloud spend. See [Cost](/docs/infrastructure-as-a-database/cost) for the full guide, response shapes, and SQL access.

## Cost

Cost analysis requires cost estimation on the server. Monetary fields are strings: parse them as decimals.

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/states/{state_id}/costs` | Latest cost snapshot for a state with a per-resource breakdown (`404` if never priced) |
| `POST` | `/api/v1/states/{state_id}/costs/calculate` | Trigger a recompute; returns `202` with a task (poll [`/api/v1/tasks/{task_id}`](/docs/reference/api/transactions#tasks)); `503` if cost estimation is off |
| `GET` | `/api/v1/states/{state_id}/costs/unsupported` | Resources that did not contribute to the totals (coverage gaps) |
| `GET` | `/api/v1/tenants/{tenant_id}/costs` | Current cost rollup across all states (`?tag_key` to break down by a tag) |
| `GET` | `/api/v1/tenants/{tenant_id}/costs/history` | Cost over time, one point per day (`?from`, `?to`, `?group_by`, `?tag_key`) |
| `GET` | `/api/v1/tenants/{tenant_id}/costs/tag-keys` | Tag keys available for grouping |
| `GET` | `/api/v1/tx/{tx_id}/costs` | Plan-time cost delta for a pending transaction (see [Plan-time cost](#plan-time-cost)) |
| `GET` | `/api/v1/states/{state_id}/costs/actuals` | Actual (FOCUS) spend attributed to the state's resources over the loaded billing window, with a per-resource breakdown |
| `GET` | `/api/v1/tenants/{tenant_id}/costs/attribution` | Actual spend split into attributed, unmanaged, and unallocated, whole-tenant and per provider (see [Billing sources](/docs/infrastructure-as-a-database/cost/billing-sources)) |
| `GET` | `/api/v1/tenants/{tenant_id}/costs/unmanaged` | Billed resources that match no managed resource, cursor-paginated (`?page`, `?limit`) |

### Cost history parameters

- `from` and `to` require a full ISO 8601 / RFC 3339 timestamp, for example `2026-06-01T00:00:00Z`. A bare calendar date such as `2026-06-01` returns `400 Bad Request` with body `{"id": "INVALID_DATE_PARAM", "data": "..."}`.
- `group_by` accepts `provider`, `type`, or `tag`. `group_by=tag` requires a `tag_key` query parameter. Without it, or with an unknown `group_by` value, the answer is `400 Bad Request` with body `{"id": "INVALID_GROUP_BY", "data": "..."}`.

### Plan-time cost

```text
GET /api/v1/tx/{tx_id}/costs
```

Returns the current-versus-planned cost delta for a transaction that `stategraph tf plan` or `stategraph tf mtx` opened. See [Plan-time cost](/docs/infrastructure-as-a-database/cost/plan-time) for the CLI and the full response shape.

- `200`: a `tx-cost-delta` with `totals` (each metric as `current_*`, `planned_*`, and `delta_*`), a per-state `states[]` list with per-resource `resources[]` (each with a `change_kind` of `added`, `removed`, or `changed`), and `by_provider`, `by_type`, and `by_tag` delta breakdowns.
- `202`: `{"status": "computing"}`. The preview is not ready yet, or the transaction was not opened through `stategraph` planning. Try again soon.
- `404`: the transaction was aborted, which deletes its planned cost.
- `401`: the caller is not a member of the tenant of the transaction.

## Billing sources

These endpoints connect cloud billing (FOCUS) exports: your actual cloud spend. They are admin only: a caller who is not an admin gets `403`. See [Billing sources](/docs/infrastructure-as-a-database/cost/billing-sources).

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/tenants/{tenant_id}/billing-sources` | List billing sources |
| `POST` | `/api/v1/tenants/{tenant_id}/billing-sources` | Create a source. Body `{provider, source_uri, region?, window_months?, enabled?}` |
| `PUT` | `/api/v1/tenants/{tenant_id}/billing-sources/{billing_source_id}` | Update a source (omitted fields unchanged) |
| `POST` | `/api/v1/tenants/{tenant_id}/billing-sources/{billing_source_id}/sync` | Trigger a sync. Body `{window_start?}` |
| `DELETE` | `/api/v1/tenants/{tenant_id}/billing-sources/{billing_source_id}` | Delete a source and its loaded billing rows |
