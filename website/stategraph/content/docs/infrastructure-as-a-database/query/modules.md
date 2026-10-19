---
title: Modules
description: Browse the Terraform modules in your states and the resources in each module, and query module usage and structure with SQL.
order: 4
---


Stategraph records the module hierarchy of your Terraform states, the resources and instances in each module, and module usage across states. A Terraform module is a reusable container for multiple resources. See the modules in the console under **Inventory > Modules**, list them with the API, or query them with SQL.

## List modules with the API

To get `STATE_ID`, see [Instances](/docs/infrastructure-as-a-database/query/instances).

```bash
curl "http://localhost:8080/api/v1/states/$STATE_ID/modules" \
  -H "Authorization: Bearer $STATEGRAPH_API_KEY"
```

Response:

```json
{
  "results": [
    {
      "name": "module.vpc",
      "instance_count": 25,
      "resource_count": 10
    },
    {
      "name": "module.vpc.module.subnets",
      "instance_count": 12,
      "resource_count": 4
    }
  ]
}
```

## Module properties

| Property | Description |
|----------|-------------|
| `name` | Full module path, such as `module.vpc.module.private_subnets` |
| `instance_count` | Total resource instances in the module |
| `resource_count` | Resources (resource blocks, or distinct resource addresses) in the module |

## Module paths

Module paths follow the Terraform module hierarchy:

<figure class="docs-figure">
<div class="docs-why-panel docs-diagram-fit">
<div class="docs-diagram-tree"><div class="docs-diagram-row"><span class="docs-why-state accent">root</span><span class="docs-diagram-note">module path is null</span></div><ul><li><span class="docs-why-state">module.vpc</span><ul><li><span class="docs-why-state">module.subnets</span></li><li><span class="docs-why-state">module.nat</span></li></ul></li><li><span class="docs-why-state">module.eks</span><ul><li><span class="docs-why-state">module.node_groups</span></li></ul></li><li><span class="docs-why-state">module.rds</span></li></ul></div>
</div>
<figcaption>The root module has a null module path.<br> <code>module.vpc</code>, <code>module.eks</code>, and <code>module.rds</code> are in the root module.<br> <code>module.subnets</code> and <code>module.nat</code> are nested in <code>module.vpc</code>, and <code>module.node_groups</code> is nested in <code>module.eks</code>.</figcaption>
</figure>

In SQL, the module path is in `resources.module`.

Root module resources (not in any module):

```sql
SELECT *
FROM resources
WHERE module IS NULL
```

Resources in `module.vpc`:

```sql
SELECT *
FROM resources
WHERE module = 'module.vpc'
```

## Module analysis

### Resources per module

```sql
SELECT module, count(*) as resources
FROM resources
WHERE module IS NOT NULL
GROUP BY module
ORDER BY module
```

### Types per module

```sql
SELECT module, type, count(*) as type_count
FROM resources
WHERE module IS NOT NULL
GROUP BY module, type
ORDER BY module, type
```

### Top-level modules

List all modules. A top-level module has no nested `module.` segment:

```sql
SELECT module, count(*) as resources
FROM resources
WHERE module IS NOT NULL
GROUP BY module
ORDER BY module
```

### Nested module depth

List the module paths. Each `module.` segment in a path is one level of nesting:

```sql
SELECT module
FROM resources
WHERE module IS NOT NULL
GROUP BY module
ORDER BY module
```

## Module usage patterns

### Find duplicate module usage

Count the states that use each module. `count(DISTINCT ...)` is not supported, so the CTE first keeps one row for each module and state:

```sql
WITH module_states AS (
  SELECT module, state_id
  FROM resources
  WHERE module IS NOT NULL
  GROUP BY module, state_id
)
SELECT module, count(*) AS states_using
FROM module_states
GROUP BY module
ORDER BY module
```

### Module resource distribution

MQL does not support `CASE`, so count root and module resources with two queries.

Resources in the root module:

```sql
SELECT count(*) AS resources
FROM resources
WHERE module IS NULL
```

Resources inside modules:

```sql
SELECT count(*) AS resources
FROM resources
WHERE module IS NOT NULL
```

### Resources by module type

```sql
SELECT module, type, count(*) as type_count
FROM resources
WHERE module = 'module.vpc'
GROUP BY module, type
ORDER BY type
```

## Common module patterns

### VPC module resources

```sql
SELECT type, count(*) as type_count
FROM resources
WHERE module = 'module.vpc'
GROUP BY type
ORDER BY type
```

### EKS/Kubernetes modules

```sql
SELECT module, type, count(*) as type_count
FROM resources
WHERE module = 'module.eks'
GROUP BY module, type
ORDER BY module, type
```

### Database modules

```sql
SELECT module, type, count(*) as type_count
FROM resources
WHERE module = 'module.rds'
GROUP BY module, type
ORDER BY module, type
```

## Best practices

- Use clear module names, one purpose per module, and shallow nesting (fewer than 3 levels).
- Track module versions in source control.
- Monitor instance counts over time, watch for module sprawl, and review cross-module dependencies.
- Put infrastructure (VPC, EKS, RDS) in modules, app resources in the root or in app modules, and common patterns in shared modules.

## Module vs root resources

Compare the resource counts of the root module and of modules.

Resources in the root module:

```sql
SELECT count(*) AS resources
FROM resources
WHERE module IS NULL
```

Resources inside modules:

```sql
SELECT count(*) AS resources
FROM resources
WHERE module IS NOT NULL
```

## Next steps

- [Instances](/docs/infrastructure-as-a-database/query/instances): browse all instances.
- [Resource Types](/docs/infrastructure-as-a-database/query/resource-types): view by type.
- [Query](/docs/infrastructure-as-a-database/query/query): advanced module queries.
- [Graph Explorer](/docs/infrastructure-as-a-database/query/graph-explorer): see module dependencies.
