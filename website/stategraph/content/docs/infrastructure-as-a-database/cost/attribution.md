---
title: Cost attribution
description: Add up the estimated cost of all managed states, attribute spend by a tag such as team, environment, or owner, and follow the cost over time.
order: 4
---


Stategraph adds up the estimated cost of all managed states in your tenant, breaks it down by provider, resource type, or tag, and follows it over time. It holds the state of record for all of your infrastructure. One call rolls up the latest snapshot of each live state.

```
GET /api/v1/tenants/{tenant_id}/costs[?tag_key=KEY]                    # rollup + breakdowns
GET /api/v1/tenants/{tenant_id}/costs/tag-keys                         # tag keys available to group by
GET /api/v1/tenants/{tenant_id}/costs/history[?from&to&group_by]      # cost over time
```

Each tenant command takes `--tenant` or reads `STATEGRAPH_TENANT_ID`, and accepts `--format=table|json|simple`. The **Overview** and **Explorer** pages in the [console](/docs/infrastructure-as-a-database/cost/console) show the same rollups.

## Tenant rollup

```bash
stategraph cost tenant --tenant $TENANT_ID
```

Or with the API:

```bash
curl -H "Authorization: Bearer $STATEGRAPH_API_KEY" \
  "$STATEGRAPH_API_BASE/api/v1/tenants/$TENANT_ID/costs"
```

It returns the tenant total, coverage, `by_provider` and `by_type` breakdowns, and the states:

```json
{
  "monthly_cost": "1573.964000",
  "currency": "USD",
  "coverage_percent": 51.3,
  "by_provider": [
    { "name": "aws", "monthly_cost": "1573.964000", "hourly_cost": "2.156116", "resource_count": 221 }
  ],
  "by_type": [
    { "name": "aws_db_instance",        "monthly_cost": "1179.900000", "resource_count": 5 },
    { "name": "aws_elasticache_cluster", "monthly_cost": "360.620000",  "resource_count": 2 },
    { "name": "aws_instance",           "monthly_cost": "31.244000",   "resource_count": 4 }
  ],
  "states": [
    { "state_name": "acme-data-stores", "monthly_cost": "1509.640000", "coverage_percent": 50.0,
      "resource_count": 24, "state_id": "5156028b-…" }
  ]
}
```

Soft-deleted states are excluded. A never-priced state appears in `states[]` with its identity and no cost fields, unlike a `$0` state.

## Attribution by tag

1. List the tag keys across your states:

```bash
stategraph cost tag-keys --tenant $TENANT_ID
```

Or with the API:

```bash
curl -H "Authorization: Bearer $STATEGRAPH_API_KEY" \
  "$STATEGRAPH_API_BASE/api/v1/tenants/$TENANT_ID/costs/tag-keys"
```

```json
{ "tag_keys": ["Environment", "Project", "Role", "Service", "Team", "Tier"] }
```

2. Break the rollup down by one key with `--tag-key` (`?tag_key=` in the API):

```bash
stategraph cost tenant --tenant $TENANT_ID --tag-key Team
```

Or with the API:

```bash
curl -H "Authorization: Bearer $STATEGRAPH_API_KEY" \
  "$STATEGRAPH_API_BASE/api/v1/tenants/$TENANT_ID/costs?tag_key=Team"
```

`by_tag` has one row per value of the key:

```json
{
  "by_tag": [
    { "name": "data",        "monthly_cost": "1149.020000", "resource_count": 13 },
    { "name": "engineering", "monthly_cost": "7.592000",    "resource_count": 20 },
    { "name": "platform",    "monthly_cost": "2.200000",    "resource_count": 52 },
    { "name": "sre",                                         "resource_count": 17 },
    { "name": "untagged",    "monthly_cost": "415.152000",  "resource_count": 103 }
  ]
}
```

- `untagged` rolls up every resource without the key. A large `untagged` figure usually shows poor tagging, not a real owner.
- Absent money is not `$0`. `$0` means "priced, costs nothing". Absent means "nothing here was priced". The `sre` row has 17 resources but no `monthly_cost`, because none is priced (free-to-create resources, or unsupported types). Show the two cases differently.
- Group by `Project`, `Service`, or any other key the same way. For example, `--tag-key Environment` splits `production` from `staging`.

## Trends over time

History comes from the append-only snapshot trail. The latest snapshot of each state carries forward to days without a recompute.

```bash
stategraph cost history --tenant $TENANT_ID --group-by provider
```

Or with the API:

```bash
curl -H "Authorization: Bearer $STATEGRAPH_API_KEY" \
  "$STATEGRAPH_API_BASE/api/v1/tenants/$TENANT_ID/costs/history?group_by=provider"
```

```json
{
  "points": [
    {
      "date": "2026-06-09",
      "monthly_cost": "1573.964000",
      "hourly_cost": "2.156116",
      "groups": [
        { "name": "aws", "monthly_cost": "1573.964000", "resource_count": 221 }
      ]
    }
  ]
}
```

`points[]` has one entry per day, oldest first, with that day's tenant total.

| CLI flag | API parameter | Description |
|----------|---------------|-------------|
| `--group-by` | `group_by` | `provider`, `type`, or `tag`. Adds a `groups[]` breakdown to each point. |
| `--tag-key` | `tag_key` | Tag key for the daily breakdown when grouping by `tag` |
| `--from` / `--to` | `from` / `to` | Window bounds in ISO 8601, a date (`2026-06-01`) or a timestamp (`2026-06-01T00:00:00Z`). Default: 30 days ago and now. |

```bash
stategraph cost history --tenant $TENANT_ID --from 2026-06-01T00:00:00Z --to 2026-06-09T00:00:00Z
```

An unparseable `from` or `to` returns `400` with id `INVALID_DATE_PARAM`. `group_by=tag` without `tag_key` also returns `400`.

## Next steps

- [Querying cost data](/docs/infrastructure-as-a-database/cost/queries): SQL beyond the rollups.
- [State and resource cost](/docs/infrastructure-as-a-database/cost/state-cost): one state, per resource.
- [Cloud billing (FOCUS)](/docs/infrastructure-as-a-database/cost/billing-sources): billed spend.
