---
title: Resource Types
description: See the resources in all your states grouped by type and provider, with counts for each type and SQL queries for type analysis.
order: 5
---


Stategraph counts the resources of each Terraform resource type, such as `aws_instance` or `google_compute_instance`, across all your states. Resource types are the building blocks of Terraform configurations. See the counts in the console under **Inventory > Resource Types**, get them with the API, or analyze them with SQL.

## Counts with the API

Get the number of instances of each type in one state. To get `STATE_ID`, see [Instances](/docs/infrastructure-as-a-database/query/instances).

```bash
curl "http://localhost:8080/api/v1/states/$STATE_ID/resources/summary" \
  -H "Authorization: Bearer $STATEGRAPH_API_KEY"
```

Response:

```json
{
  "aws_instance": { "instances": 20 },
  "aws_security_group": { "instances": 15 },
  "aws_subnet": { "instances": 6 },
  "aws_iam_role": { "instances": 12 }
}
```

### Tenant-wide breakdown

The tenant endpoint gives, for each state and type, how many resources the state declares and how many instances are deployed. The console shows the same data under **Settings > Resource Types**. Add `state_id` for one state:

```bash
curl "http://localhost:8080/api/v1/tenants/$TENANT_ID/resource-types" \
  -H "Authorization: Bearer $STATEGRAPH_API_KEY"
```

Response:

```json
{
  "resource_types": [
    {
      "state_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "state_name": "networking",
      "type": "aws_subnet",
      "resource_count": 2,
      "instance_count": 6
    }
  ],
  "total_resources": 2,
  "total_instances": 6
}
```

`instance_count` is larger than `resource_count` when `count` or `for_each` expands one address into several objects. A type with nothing deployed has no entry.

## Type analysis

### Count all types

```sql
SELECT type, count(*) as type_count
FROM resources
GROUP BY type
ORDER BY count(*) DESC
```

### Types by provider

`provider` holds the full provider source address, such as `provider["registry.terraform.io/hashicorp/aws"]`. Match it with `LIKE`.

AWS resources:

```sql
SELECT type, count(*) as type_count
FROM resources
WHERE provider LIKE '%hashicorp/aws%'
GROUP BY type
ORDER BY count(*) DESC
```

Google Cloud resources:

```sql
SELECT type, count(*) as type_count
FROM resources
WHERE provider LIKE '%hashicorp/google%'
GROUP BY type
ORDER BY count(*) DESC
```

Azure resources:

```sql
SELECT type, count(*) as type_count
FROM resources
WHERE provider LIKE '%hashicorp/azurerm%'
GROUP BY type
ORDER BY count(*) DESC
```

### Unique types per state

MQL does not support `count(DISTINCT ...)`. Dedupe with a CTE, then count:

```sql
WITH state_types AS (
  SELECT state_id, type
  FROM resources
  GROUP BY state_id, type
)
SELECT state_id, count(*) AS types
FROM state_types
GROUP BY state_id
ORDER BY types DESC
```

## Common resource types

| Type | Description |
|------|-------------|
| `aws_instance` | EC2 instances |
| `aws_security_group` | Security groups |
| `aws_iam_role` | IAM roles |
| `aws_s3_bucket` | S3 buckets |
| `aws_subnet` | VPC subnets |
| `aws_vpc` | Virtual private clouds |
| `aws_lambda_function` | Lambda functions |
| `aws_db_instance` | RDS instances |
| `google_compute_instance` | Compute Engine VMs |
| `google_storage_bucket` | Cloud Storage buckets |
| `google_container_cluster` | GKE clusters |
| `google_sql_database_instance` | Cloud SQL instances |
| `azurerm_virtual_machine` | Virtual machines |
| `azurerm_storage_account` | Storage accounts |
| `azurerm_kubernetes_cluster` | AKS clusters |
| `azurerm_sql_server` | SQL servers |

## Type-specific queries

### EC2 instances by type

```sql
SELECT i.attributes#>>'{instance_type}' AS instance_type, count(*) AS instance_count
FROM instances AS i
INNER JOIN resources AS r
  ON i.resource_address = r.address AND i.state_id = r.state_id
WHERE r.type = 'aws_instance'
GROUP BY i.attributes#>>'{instance_type}'
ORDER BY count(*) DESC
```

### S3 buckets by region

```sql
SELECT i.attributes#>>'{region}' AS region, count(*) AS region_count
FROM instances AS i
INNER JOIN resources AS r
  ON i.resource_address = r.address AND i.state_id = r.state_id
WHERE r.type = 'aws_s3_bucket'
GROUP BY i.attributes#>>'{region}'
ORDER BY count(*) DESC
```

### RDS instances by engine

```sql
SELECT i.attributes#>>'{engine}' AS engine, count(*) AS engine_count
FROM instances AS i
INNER JOIN resources AS r
  ON i.resource_address = r.address AND i.state_id = r.state_id
WHERE r.type = 'aws_db_instance'
GROUP BY i.attributes#>>'{engine}'
ORDER BY count(*) DESC
```

### Lambda functions by runtime

```sql
SELECT i.attributes#>>'{runtime}' AS runtime, count(*) AS runtime_count
FROM instances AS i
INNER JOIN resources AS r
  ON i.resource_address = r.address AND i.state_id = r.state_id
WHERE r.type = 'aws_lambda_function'
GROUP BY i.attributes#>>'{runtime}'
ORDER BY count(*) DESC
```

## Resource categories

### Compute resources

```sql
SELECT type, count(*) as type_count
FROM resources
WHERE type IN (
  'aws_instance',
  'aws_lambda_function',
  'aws_ecs_service',
  'google_compute_instance',
  'azurerm_virtual_machine'
)
GROUP BY type
ORDER BY count(*) DESC
```

### Storage resources

```sql
SELECT type, count(*) as type_count
FROM resources
WHERE type IN (
  'aws_s3_bucket',
  'aws_ebs_volume',
  'google_storage_bucket',
  'azurerm_storage_account'
)
GROUP BY type
ORDER BY count(*) DESC
```

### Network resources

```sql
SELECT type, count(*) as type_count
FROM resources
WHERE type IN (
  'aws_vpc',
  'aws_subnet',
  'aws_security_group',
  'aws_network_interface',
  'google_compute_network',
  'google_compute_subnetwork',
  'azurerm_virtual_network',
  'azurerm_subnet'
)
GROUP BY type
ORDER BY count(*) DESC
```

### Security resources

```sql
SELECT type, count(*) as type_count
FROM resources
WHERE type IN (
  'aws_iam_role',
  'aws_iam_policy',
  'aws_iam_user',
  'aws_kms_key',
  'aws_secretsmanager_secret'
)
GROUP BY type
ORDER BY count(*) DESC
```

## Type distribution analysis

### Types per workspace

```sql
SELECT state_id, type, count(*) as type_count
FROM resources
GROUP BY state_id, type
ORDER BY state_id, count(*) DESC
```

### New resource types

Types in only one state can be new additions:

```sql
WITH type_states AS (
  SELECT type, state_id
  FROM resources
  GROUP BY type, state_id
)
SELECT type, count(*) AS states_count
FROM type_states
GROUP BY type
HAVING count(*) = 1
ORDER BY type
```

### Most common types

```sql
SELECT type, count(*) as type_count
FROM resources
GROUP BY type
ORDER BY count(*) DESC
LIMIT 10
```

## Monitoring type growth

To track type growth, compare the counts at regular intervals:

```sql
SELECT type, count(*) as type_count
FROM resources
GROUP BY type
ORDER BY count(*) DESC
```

Save these queries to a [dashboard](/docs/infrastructure-as-a-database/query/dashboards). Check that the type distribution is appropriate, and compare the expected and actual counts to find drift and unexpected types.

## Next steps

- [Instances](/docs/infrastructure-as-a-database/query/instances): browse all instances.
- [Modules](/docs/infrastructure-as-a-database/query/modules): view by module.
- [Query](/docs/infrastructure-as-a-database/query/query): advanced queries.
- [Dashboards](/docs/infrastructure-as-a-database/query/dashboards): save type queries.
