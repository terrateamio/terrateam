---
title: Querying cost data
description: Query Stategraph cost snapshots with SQL to rank resources by cost, break spend down by type or tag, and find coverage gaps across your states.
order: 6
---


Cost snapshots are two SQL tables, so you can slice spend beyond the rollups. Run the queries on the console [Query](/docs/infrastructure-as-a-database/query/query) page or with [`stategraph sql query`](/docs/cli/sql). See [SQL Syntax](/docs/reference/sql-syntax).

| Table | One row per | Key columns |
|-------|-------------|-------------|
| `cost_snapshots` | state snapshot | `state_id`, `kind`, `monthly_cost`, `hourly_cost`, `currency`, `resource_count`, `supported_count`, `priced_count`, `calculated_at`, `tx_id` |
| `cost_snapshot_resources` | resource in a snapshot | `snapshot_id`, `address`, `type`, `provider`, `region`, `monthly_cost`, `hourly_cost`, `supported`, `no_price`, `tags`, `components` |

Join them on `cost_snapshot_resources.snapshot_id = cost_snapshots.id`.

## Working with snapshots

- Money is text. `monthly_cost` and `hourly_cost` are strings, to keep precision, and `NULL` when a resource has no billable cost. Cast with `::real` for math, and filter `WHERE monthly_cost IS NOT NULL` before you rank or sum.
- Snapshots are append-only, so a state gets a new `kind = 'current'` row at each recompute. To avoid double counts, scope a query to one `snapshot_id` (below), or use the [rollup API](/docs/infrastructure-as-a-database/cost/attribution#tenant-rollup), which uses only the latest snapshot of each state.
- `kind` is `current` for realized or scheduled estimates, or `planned` for plan-time predictions from `stategraph tf plan` and `stategraph tf mtx`, each tied to a `tx_id`. Filter `WHERE kind = 'current'` to exclude the predictions, as the examples do.

The latest snapshot id of a state:

```sql
SELECT id FROM cost_snapshots
WHERE state_id = '5156028b-…' AND kind = 'current'
ORDER BY calculated_at DESC LIMIT 1
```

## Example queries

### Per-state totals

```sql
SELECT state_id, monthly_cost, priced_count, resource_count
FROM cost_snapshots
WHERE kind = 'current' AND monthly_cost IS NOT NULL
ORDER BY monthly_cost::real DESC
LIMIT 4
```

Output:

```
state_id                              monthly_cost  priced_count  resource_count
------------------------------------  ------------  ------------  --------------
5156028b-d378-4ab6-8a8b-4a783e633bc6  1509.640000   21            34
3523a799-01bd-47cc-bdc2-7c72f628f24e  130.816000    5             8
2d531a2c-299d-4787-ba47-6c75c9723516  38.472000     3             3
```

### Most expensive resources in a state

```sql
SELECT address, type, monthly_cost
FROM cost_snapshot_resources
WHERE snapshot_id = '9eb9021d-…' AND monthly_cost IS NOT NULL
ORDER BY monthly_cost::real DESC
LIMIT 5
```

Output:

```
address                            type                     monthly_cost
---------------------------------  -----------------------  ------------
aws_db_instance.primary            aws_db_instance          656.270000
aws_db_instance.replica_1          aws_db_instance          328.500000
aws_elasticache_cluster.app_cache  aws_elasticache_cluster  240.170000
aws_db_instance.replica_2          aws_db_instance          164.250000
aws_elasticache_cluster.sessions   aws_elasticache_cluster  120.450000
```

### Monthly cost by resource type

`count` is a reserved word, so alias the count (here `cnt`), and sort by the aggregate expression, not the alias:

```sql
SELECT type, sum(monthly_cost::real) AS monthly, count(*) AS cnt
FROM cost_snapshot_resources
WHERE snapshot_id = '9eb9021d-…' AND monthly_cost IS NOT NULL
GROUP BY type
ORDER BY sum(monthly_cost::real) DESC
LIMIT 5
```

Output:

```
type                     monthly  cnt
-----------------------  -------  ---
aws_db_instance          1149.02  3
aws_elasticache_cluster  360.62   2
```

### Cost by tag

Extract a tag with the `#>>` path operator (not `->>` inside `GROUP BY`). The `NULL` group holds the resources without that tag:

```sql
SELECT tags#>>'{Team}' AS team, sum(monthly_cost::real) AS monthly
FROM cost_snapshot_resources
WHERE snapshot_id = '9eb9021d-…' AND monthly_cost IS NOT NULL
GROUP BY tags#>>'{Team}'
ORDER BY sum(monthly_cost::real) DESC
```

Output:

```
team  monthly
----  -------
data  1149.02
      360.62
```

For tenant-wide tag attribution, use the [tag-key rollup](/docs/infrastructure-as-a-database/cost/attribution#attribution-by-tag). It counts each state once and groups untagged resources.

### Coverage gaps

Recognized `no_price` resources, which are not in the totals:

```sql
SELECT type, count(*) AS cnt
FROM cost_snapshot_resources
WHERE snapshot_id = '9eb9021d-…' AND no_price
GROUP BY type
ORDER BY count(*) DESC
```

## Next steps

- [Cost attribution](/docs/infrastructure-as-a-database/cost/attribution): tenant rollups and tag attribution.
- [SQL Syntax](/docs/reference/sql-syntax): the query language.
- [Query](/docs/infrastructure-as-a-database/query/query): SQL in the console.
