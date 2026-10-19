---
title: Query and insights
description: Browse, search, and query your Terraform inventory in the console or with SQL, and see the change history, blast radius, and dependencies.
order: 1
---


You can browse, search, and analyze the resources of all your Terraform states in the console, or query them with SQL. Infrastructure as a Database stores each state as a graph in PostgreSQL, and the console screens and SQL read the same tables.

## Inventory

The catalog of everything Terraform manages, across all your states:

- [Instances](/docs/infrastructure-as-a-database/query/instances): every resource instance, with attributes and dependencies.
- [Modules](/docs/infrastructure-as-a-database/query/modules): the module hierarchy and the resources in each module.
- [Resource Types](/docs/infrastructure-as-a-database/query/resource-types): resources grouped by type and provider.
- [Gap Analysis](/docs/infrastructure-as-a-database/query/gap-analysis): cloud resources that no Terraform state manages.

## Insights

Analysis of the dependency graph and its history:

- [Timeline](/docs/infrastructure-as-a-database/query/timeline): transaction history, who changed what and when.
- [Search](/docs/infrastructure-as-a-database/query/search): find instances by type, module, provider, address, or attribute value.
- [Blast Radius](/docs/infrastructure-as-a-database/query/blast-radius): every resource that a change can affect.
- [Graph Explorer](/docs/infrastructure-as-a-database/query/graph-explorer): interactive dependency view.
- [Dashboard Metrics](/docs/infrastructure-as-a-database/query/dashboard-metrics): what each metric on the console home page means.

## SQL

Every table behind the console accepts SQL queries:

- [Query (SQL)](/docs/infrastructure-as-a-database/query/query): tables, operators, JSON access, joins, and examples.
- [Dashboards](/docs/infrastructure-as-a-database/query/dashboards): save queries as table and chart panels.

Run the same queries from the console, from the CLI with `stategraph sql query`, or from the API at `/api/v1/mql`. `stategraph sql schema` lists all tables and columns.

### Orchestration data

With Stategraph Orchestration on, MQL also queries its GitHub and GitLab data for your tenant: runs, pull requests, gates, drift schedules, pull request stacks, unlock timestamps, and more. See [Query (SQL)](/docs/infrastructure-as-a-database/query/query).

## Use cases

- Infrastructure catalog: use the inventory as your CMDB, with counts by type, module, or provider.
- Compliance and auditing: find resources by tag, attribute, region, or account, find missing required tags, make compliance reports, and see who changed what and when in the Timeline.
- Resource discovery: find duplicate or similar resources, naming patterns, and unmanaged resources with Gap Analysis.
- Change planning: check the impact with Blast Radius, find critical dependencies, plan a safe order, and tell stakeholders the scope.
- Architecture: see relationships, module structure, and isolated resources in the Graph Explorer, and document your infrastructure.

## Quick examples

### Find all EC2 instances

In the console, see `aws_instance` under **Inventory > Resource Types**. Or run this query:

```sql
SELECT i.address, i.attributes->>'instance_type' AS instance_type
FROM instances AS i
INNER JOIN resources AS r
  ON i.resource_address = r.address AND i.state_id = r.state_id
WHERE r.type = 'aws_instance'
```

### Count resources by type

```sql
SELECT type, count(*) AS total
FROM resources
GROUP BY type
ORDER BY type
```

### Find untagged resources

```sql
SELECT address
FROM instances
WHERE attributes->'tags' IS NULL
  OR attributes->>'tags' = '{}'
```

## Getting started

1. [Deploy Stategraph](/docs/admin/self-hosting/docker-compose), if you have not already.
2. [Import your state](/docs/infrastructure-as-a-database/setup) to fill the inventory.
3. Browse **Resources** to see what you have.
4. Run a query to explore the data.
