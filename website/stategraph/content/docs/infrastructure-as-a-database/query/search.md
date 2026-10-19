---
title: Search
description: Find resource instances in all your states by type, module, provider, address, or attribute value on the Search screen in Insights.
order: 10
---


Search finds resource instances by field, in one state or in all the states of your tenant. It is in the console under **Insights > Search**. For aggregation, joins, and complex conditions, use [Query (SQL)](/docs/infrastructure-as-a-database/query/query).

## What you can filter by

| Field | Matches |
|-------|---------|
| `type` | Resource type, such as `aws_instance` |
| `module` | Module path |
| `provider` | Provider |
| `address` | Full instance address |
| `resource_address` | Resource address (without index) |
| `attr:<key>:<value>` | An attribute value (JSON containment) |

A word without a field matches part of the type, the address, or the module.

## Via the API

The instances endpoint takes the same field filters for one state, in a `q` query of space-separated `key:value` terms:

```bash
# EC2 instances
curl "http://localhost:8080/api/v1/states/$STATE_ID/instances?q=type:aws_instance" \
  -H "Authorization: Bearer $STATEGRAPH_API_KEY"

# Instances in a module with a specific attribute value
curl "http://localhost:8080/api/v1/states/$STATE_ID/instances?q=module:vpc%20attr:instance_type:t3.micro" \
  -H "Authorization: Bearer $STATEGRAPH_API_KEY"
```

`attr:<key>:<value>` matches instances whose `attributes` JSON contains that key and value. The endpoint pages results with `page` and `limit` (default 20).

## Search vs Query

| | Search | [Query (SQL)](/docs/infrastructure-as-a-database/query/query) |
|--|--------|----------------------------------|
| Input | Field filters (`type:`, `module:`, `attr:...`) | SQL / MQL |
| Best for | Finding and opening instances quickly | Aggregation, joins, complex filters, export |
| Scope | Instances | Any table (resources, instances, transactions, costs, and more) |

## Next steps

- [Blast Radius](/docs/infrastructure-as-a-database/query/blast-radius): analyze the impact of a change.
- [Graph Explorer](/docs/infrastructure-as-a-database/query/graph-explorer): see dependencies.
- [Query (SQL)](/docs/infrastructure-as-a-database/query/query): full SQL/MQL analysis.
- [Instances](/docs/infrastructure-as-a-database/query/instances): browse all instances.
