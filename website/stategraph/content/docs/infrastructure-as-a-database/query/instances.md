---
title: Instances
description: Browse the resource instances in all your Terraform states. Filter them, and inspect the attributes and dependencies of each one.
order: 3
---


You can browse the resource instances of all your Terraform states in the console, list them with the API, and filter them with SQL.

An instance is one resource that Terraform manages. This configuration makes three instances, `aws_instance.web[0]` to `aws_instance.web[2]`:

```hcl
resource "aws_instance" "web" {
  count = 3
  # ...
}
```

In the console, the instances are under **Inventory > Resources**.

## List instances with the API

1. Get your state ID:

```bash
export STATEGRAPH_API_KEY="<your-api-key>"
TENANT_ID=$(curl -s -H "Authorization: Bearer $STATEGRAPH_API_KEY" \
  http://localhost:8080/api/v1/user/tenants | jq -r '.results[0].id')
STATE_ID=$(curl -s -H "Authorization: Bearer $STATEGRAPH_API_KEY" \
  "http://localhost:8080/api/v1/tenants/$TENANT_ID/states" | jq -r '.results[0].id')
```

2. List the instances:

```bash
curl "http://localhost:8080/api/v1/states/$STATE_ID/instances" \
  -H "Authorization: Bearer $STATEGRAPH_API_KEY"
```

Response:

```json
{
  "results": [
    {
      "address": "aws_instance.web[0]",
      "type": "aws_instance",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "attributes": { ... },
      "dependencies": ["aws_subnet.main", "aws_security_group.web"]
    }
  ]
}
```

## Instance properties

| Property | Description |
|----------|-------------|
| `address` | Full Terraform address, such as `module.vpc.aws_subnet.private[0]` |
| `type` | Resource type, such as `aws_instance` or `google_compute_instance` |
| `provider` | Provider that manages the resource |
| `module` | Module path. Omitted for root resources. |
| `attributes` | JSON object of all resource attributes |
| `dependencies` | Resources that this instance depends on |
| `sensitive_attributes` | Present only when the instance has sensitive attributes. |

## Filtering instances

In SQL, the `instances` table holds per-instance data (`attributes`, `dependencies`, `status`). Resource `type`, `provider`, and `module` are in the `resources` table. Query `resources` directly, or join on `resource_address` (see [Query](/docs/infrastructure-as-a-database/query/query#cross-table-queries)). The API response above includes `type`, `provider`, and `module`.

### By resource type

```sql
SELECT * FROM resources
WHERE type = 'aws_instance'
```

### By provider

`provider` holds the full provider source address, such as `provider["registry.terraform.io/hashicorp/aws"]`. Match it with `LIKE`.

AWS resources:

```sql
SELECT * FROM resources
WHERE provider LIKE '%hashicorp/aws%'
```

Google Cloud resources:

```sql
SELECT * FROM resources
WHERE provider LIKE '%hashicorp/google%'
```

### By module

All resources in modules:

```sql
SELECT * FROM resources
WHERE module IS NOT NULL
```

Resources in a specific module:

```sql
SELECT * FROM resources
WHERE module = 'module.vpc'
```

Root module only:

```sql
SELECT * FROM resources
WHERE module IS NULL
```

### By state

`state_id` is the UUID of the state. Look it up by name in the `states` table:

```sql
SELECT * FROM instances
WHERE state_id = '550e8400-e29b-41d4-a716-446655440000'
```

To filter by state name, join to `states`:

```sql
SELECT * FROM instances AS i
INNER JOIN states AS s ON i.state_id = s.id
WHERE s.name = 'networking'
```

### By address pattern

One address:

```sql
SELECT * FROM instances WHERE address = 'aws_db_instance.database'
```

All addresses that start with `module.vpc.`:

```sql
SELECT * FROM instances WHERE address LIKE 'module.vpc.%'
```

## Common use cases

### Find all EC2 instances

```sql
SELECT i.address, i.attributes->>'instance_type' AS instance_type
FROM instances AS i
INNER JOIN resources AS r
  ON i.resource_address = r.address AND i.state_id = r.state_id
WHERE r.type = 'aws_instance'
```

### Find resources by tag

```sql
SELECT address, attributes->'tags'->>'Name' as name
FROM instances
WHERE attributes->'tags'->>'Environment' = 'production'
```

### Count by instance type

```sql
SELECT i.attributes#>>'{instance_type}' AS instance_type, count(*) AS instance_count
FROM instances AS i
INNER JOIN resources AS r
  ON i.resource_address = r.address AND i.state_id = r.state_id
WHERE r.type = 'aws_instance'
GROUP BY i.attributes#>>'{instance_type}'
ORDER BY i.attributes#>>'{instance_type}'
```

### Find resources without tags

```sql
SELECT address, resource_address
FROM instances
WHERE attributes->'tags' IS NULL
   OR attributes->>'tags' = '{}'
```

### List security groups

```sql
SELECT
  i.address,
  i.attributes->>'name' AS name,
  i.attributes->>'vpc_id' AS vpc
FROM instances AS i
INNER JOIN resources AS r
  ON i.resource_address = r.address AND i.state_id = r.state_id
WHERE r.type = 'aws_security_group'
```

## Export

The **Query** screen exports query results as CSV. To export JSON with the API:

```bash
curl "http://localhost:8080/api/v1/mql?q=SELECT%20*%20FROM%20instances" \
  -H "Authorization: Bearer $STATEGRAPH_API_KEY" \
  > instances.json
```

Without a `LIMIT`, a query returns the default page of 20 rows. For more, add a `LIMIT` (maximum 1000) or use the `page` parameter.

## Best practices

- In large deployments, filter instead of browsing all instances.
- See the resource distribution on the Resource Types screen.
- Save frequent filters in Dashboards.
- Check the blast radius before you change resources.

## Next steps

- [Resource Types](/docs/infrastructure-as-a-database/query/resource-types): view by type.
- [Modules](/docs/infrastructure-as-a-database/query/modules): view by module.
- [Query](/docs/infrastructure-as-a-database/query/query): advanced queries.
- [Blast Radius](/docs/infrastructure-as-a-database/query/blast-radius): impact analysis.
