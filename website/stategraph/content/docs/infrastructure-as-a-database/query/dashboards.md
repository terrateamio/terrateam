---
title: Dashboards
description: Build dashboards in the Stategraph console from saved SQL queries, filters, and charts, for quick access to views of your infrastructure.
order: 7
---


Dashboards keep your frequent SQL queries as chart panels, for quick views of your infrastructure. Dashboards are saved in your browser, so other users do not see them.

## Creating dashboards

Create dashboards on the **Dashboards** page of the console. Each panel of a dashboard is a saved SQL query:

<figure class="docs-figure">
<div class="docs-why-panel">
<p class="docs-why-label">Production Overview</p>
<div class="docs-diagram-cards">
<div class="docs-diagram-card"><p class="docs-diagram-card-title">Resource Summary</p><span class="docs-diagram-note">SELECT type, COUNT(*) ...</span></div>
<div class="docs-diagram-card"><p class="docs-diagram-card-title">Recent Changes</p><span class="docs-diagram-note">SELECT * FROM transactions ...</span></div>
<div class="docs-diagram-card"><p class="docs-diagram-card-title">Untagged Resources</p><span class="docs-diagram-note">SELECT * FROM instances WHERE <span class="docs-diagram-keep">attributes-&gt;'tags'</span> IS NULL</span></div>
</div>
</div>
<figcaption>The Production Overview dashboard has three panels.<br> Each panel is a saved SQL query.</figcaption>
</figure>

## Panels

A panel shows its query as a bar, pie, or treemap chart. The chart counts rows per value of one field, for example resources by type or by provider. This query counts resources by type:

```sql
SELECT type, count(*) as type_count
FROM resources
GROUP BY type
ORDER BY count(*) DESC
LIMIT 10
```

## Example dashboards

### Infrastructure overview

<figure class="docs-figure">
<div class="docs-why-panel">
<p class="docs-why-label">Infrastructure Overview</p>
<div class="docs-diagram-cards four">
<div class="docs-diagram-card"><p class="docs-diagram-card-name">Total Resources</p><p class="docs-diagram-card-value">1,234</p></div>
<div class="docs-diagram-card"><p class="docs-diagram-card-name">States</p><p class="docs-diagram-card-value">15</p></div>
<div class="docs-diagram-card"><p class="docs-diagram-card-name">Workspaces</p><p class="docs-diagram-card-value">3</p></div>
<div class="docs-diagram-card"><p class="docs-diagram-card-name">Last Update</p><p class="docs-diagram-card-value">2 min ago</p></div>
</div>
<p class="docs-diagram-sub">Resources by Type</p>
<div class="docs-diagram-bars">
<div class="docs-why-lane"><span class="docs-why-name">aws_instance</span><span class="docs-why-track"><span class="docs-why-bar docs-diagram-bar" style="--w: 100%">234</span></span></div>
<div class="docs-why-lane"><span class="docs-why-name">aws_security_group</span><span class="docs-why-track"><span class="docs-why-bar docs-diagram-bar" style="--w: 66.7%">156</span></span></div>
<div class="docs-why-lane"><span class="docs-why-name">aws_iam_role</span><span class="docs-why-track"><span class="docs-why-bar docs-diagram-bar" style="--w: 52.6%">123</span></span></div>
<div class="docs-why-lane"><span class="docs-why-name">aws_s3_bucket</span><span class="docs-why-track"><span class="docs-why-bar docs-diagram-bar" style="--w: 38%">89</span></span></div>
</div>
<p class="docs-diagram-sub">Recent Changes</p>
<div class="docs-diagram-rows">
<div><span class="docs-diagram-note">10:30</span><span>jane@example.com</span><span class="docs-why-state">networking/prod</span></div>
<div><span class="docs-diagram-note">10:15</span><span>ci@example.com</span><span class="docs-why-state">kubernetes/staging</span></div>
<div><span class="docs-diagram-note">09:45</span><span>jane@example.com</span><span class="docs-why-state">database/prod</span></div>
</div>
</div>
<figcaption>The Infrastructure Overview dashboard: 1,234 resources in 15 states and 3 workspaces, the resources by type, and the recent changes.</figcaption>
</figure>

### Security dashboard

Resource `type` is in the `resources` table, so join `instances` to `resources` to filter by type.

Security groups:

```sql
SELECT i.address, i.attributes->>'name' AS name
FROM instances AS i
INNER JOIN resources AS r
  ON i.resource_address = r.address AND i.state_id = r.state_id
WHERE r.type = 'aws_security_group'
```

IAM roles:

```sql
SELECT i.address, i.attributes->>'name' AS name
FROM instances AS i
INNER JOIN resources AS r
  ON i.resource_address = r.address AND i.state_id = r.state_id
WHERE r.type = 'aws_iam_role'
```

### Instance type distribution

Count instances by EC2 type or RDS class. For actual cost data, see [Cost intelligence](/docs/infrastructure-as-a-database/cost).

```sql
SELECT i.attributes#>>'{instance_type}' AS instance_type, COUNT(*) AS instance_count
FROM instances AS i
INNER JOIN resources AS r
  ON i.resource_address = r.address AND i.state_id = r.state_id
WHERE r.type = 'aws_instance'
GROUP BY i.attributes#>>'{instance_type}'
ORDER BY COUNT(*) DESC
```

## Useful queries

### Resource inventory

All resources by type:

```sql
SELECT type, count(*) as type_count
FROM resources
GROUP BY type
ORDER BY type
```

Resources by workspace:

```sql
SELECT s.workspace, count(*) as resources
FROM resources AS r
INNER JOIN states AS s ON r.state_id = s.id
GROUP BY s.workspace
ORDER BY s.workspace
```

### Compliance

Resources without tags:

```sql
SELECT address, resource_address
FROM instances
WHERE attributes->'tags' IS NULL
   OR attributes->>'tags' = '{}'
```

Resources without the required `Environment` tag:

```sql
SELECT address, resource_address
FROM instances
WHERE attributes->'tags'->>'Environment' IS NULL
```

### Security

Security groups:

```sql
SELECT i.address, i.attributes->>'name' AS name
FROM instances AS i
INNER JOIN resources AS r
  ON i.resource_address = r.address AND i.state_id = r.state_id
WHERE r.type = 'aws_security_group'
```

IAM users. Keep their number small:

```sql
SELECT i.address
FROM instances AS i
INNER JOIN resources AS r
  ON i.resource_address = r.address AND i.state_id = r.state_id
WHERE r.type = 'aws_iam_user'
```

### Change tracking

States changed most recently. Stategraph sets `updated_at` when a transaction writes to the state:

```sql
SELECT name, workspace, updated_at
FROM states
ORDER BY updated_at DESC
LIMIT 10
```

## Sharing dashboards

To share a view:

- Copy the SQL of each panel, so that others can recreate or save it.
- Export the results of a query from the **Query** page, for example to CSV, as a point-in-time snapshot.

## Best practices

- Use names that tell the purpose, and describe what each panel shows.
- Group related queries. Create dashboards per team or function, and keep operational and security dashboards apart.
- Add date ranges where relevant.
- Use `LIMIT` for large result sets, filter early, and avoid `SELECT *` when possible.
- Review dashboards regularly as your infrastructure changes: check queries after major changes, and update dashboards when you add new resource types.
- Remove obsolete panels, and archive outdated dashboards.

## Next steps

- [Query (SQL)](/docs/infrastructure-as-a-database/query/query): SQL syntax.
- [API Reference](/docs/reference/api): programmatic access.
- [Dashboard metrics](/docs/infrastructure-as-a-database/query/dashboard-metrics): console home metrics.
- [Timeline](/docs/infrastructure-as-a-database/query/timeline): transaction history.
