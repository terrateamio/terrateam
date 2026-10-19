---
title: Plan-time cost
description: See the cost of a Terraform change before you apply it: Stategraph shows the current cost, the planned cost, and the delta under the plan diff.
order: 2
---


Stategraph prices a change before you apply it: [`stategraph tf plan`](/docs/infrastructure-as-a-database/transactions) prints the current cost, the planned cost, and the delta under the diff. You see an expensive change in review, not on next month's bill.

Stategraph Orchestration adds a separate Infracost estimate in a comment on the pull request. See [Cost Estimation in Pull Requests](/docs/orchestration/external-tools/infracost).

## At plan time

`stategraph tf plan` prints a `Costs:` block after the plan:

```bash
stategraph tf plan --tenant <tenant-id> --out plan.json
```

Output:

```
Plan: 1 to add, 0 to change, 0 to destroy.

Costs:
  Totals:
    Monthly:  — → 60.74 USD   (+60.74 USD)
    Hourly:   — → 0.08 USD   (+0.08 USD)
    Resources: 0 → 1 (+1)
    Coverage: 100.0% (unchanged)
  Per state:
    cost-preview-demo: +60.74/mo  (resources +1)
      + aws_instance.web                                    +60.74
```

Each `Totals` line reads `current → planned   (±delta)`. A dash means that side has nothing priced: here the state is new, and the plan adds `$60.74/mo`. A change to existing infrastructure shows both sides, like `Monthly:  130.82 USD → 140.16 USD   (+9.34 USD)`.

The delta is best effort and never blocks the plan. If the preview is not ready, you see a hint instead:

```
Costs: preview not yet ready. Run `stategraph tx costs --tx <tx-id>` to view it later.
```

- The plan waits up to `--costs-wait` seconds (default `3`) for the delta. Raise it to wait longer, or set a default for the deployment with the `STATEGRAPH_COSTS_WAIT_SECONDS` environment variable.
- The flag also applies to `stategraph tf mtx`, and to `stategraph tf apply` without a plan file. That command plans first, and applies without the delta if the preview is late.
- `--skip-costs` turns the fetch off. `--costs-wait` with `--skip-costs` is a usage error. The environment variable with `--skip-costs` is allowed, and `--skip-costs` wins.
- Pass `--out` to fetch the delta later. Without it, the plan is a read-only preview with a transient transaction, and the hint says that you cannot fetch it later.
- The plan prints no cost block when the server has [cost analysis off](/docs/admin/self-hosting/cost), or on a fetch error.

All flags are in [tf commands](/docs/cli/tf).

## On demand

To print the same `Costs:` block later for a transaction that a plan opened, for example after the "preview not yet ready" hint:

```bash
stategraph tx costs --tx <tx-id>
```

The delta comes from the plan preview that the CLI submits. Only transactions that `stategraph tf plan` or `stategraph tf mtx` opened have a preview. A transaction that you create with `stategraph tx create` has none. See [Transaction commands](/docs/cli/transactions).

## Reading the delta

The per-state breakdown marks each resource:

| Marker | Meaning |
|--------|---------|
| `+` | Added: a new resource. Its full planned cost is the delta. |
| `-` | Removed: a destroyed resource. Its cost comes off the total. |
| `~` | Changed: an in-place update. The delta is the cost difference. |

A `+0.00` delta means the change does not affect the price, or the resource has no price. A state that the plan touches without a cost change shows `no cost change`.

## API

The CLI wraps `GET /api/v1/tx/{tx_id}/costs`:

```bash
curl -H "Authorization: Bearer $STATEGRAPH_API_KEY" \
  "$STATEGRAPH_API_BASE/api/v1/tx/$TX_ID/costs"
```

- `200`: a `tx-cost-delta` (below).
- `202`: `{ "status": "computing" }`. The preview is still in progress. Retry shortly.
- `404`: the transaction does not exist, is in a tenant that you are not a member of, or was aborted. The response does not tell these cases apart.

An abort deletes the planned cost. A committed transaction keeps its planned cost and still returns the delta.

A `tx-cost-delta` has:

- `totals`: each metric as `current_*`, `planned_*`, and `delta_*`.
- `states[]`: one entry per state, with a per-resource `resources[]` list. Each resource has a `change_kind` of `added`, `removed`, or `changed`.
- `by_provider`, `by_type`, and `by_tag`: delta breakdowns.

```json
{
  "totals": {
    "currency": "USD",
    "current_monthly_cost": null,
    "planned_monthly_cost": "60.736000",
    "delta_monthly_cost": "60.736000",
    "current_resource_count": 0,
    "planned_resource_count": 1,
    "delta_resource_count": 1
  },
  "states": [
    {
      "state_id": "…",
      "state_name": "cost-preview-demo",
      "delta_monthly_cost": "60.736000",
      "resources": [
        { "address": "aws_instance.web", "type": "aws_instance", "provider": "aws",
          "change_kind": "added", "delta_monthly_cost": "60.736000" }
      ]
    }
  ]
}
```

Money fields are decimal strings, and `null` or absent when a side has nothing priced. The full schema is in the [API Reference](/docs/reference/api/cost#plan-time-cost).

## Next steps

- [State and resource cost](/docs/infrastructure-as-a-database/cost/state-cost): the current cost.
- [Cost attribution](/docs/infrastructure-as-a-database/cost/attribution): cost across the tenant.
- [Transactions](/docs/infrastructure-as-a-database/transactions): how a plan opens a transaction.
