---
title: Blast radius analysis
description: Find all resources that a change to one resource can affect, across linked states, before you make the change.
order: 11
---


Blast radius analysis shows all resources that a change to one resource instance, or its destruction, can affect.

## What is blast radius?

When a resource changes, its dependents can also need an update or a replacement. Stategraph computes the blast radius from the dependency graph of the Terraform configuration. The graph follows references into linked states, so it includes dependents in other states.

<figure class="docs-figure">
<div class="docs-diagram-stages two">
<div class="docs-why-panel"><p class="docs-why-label">Change</p><div class="docs-why-states"><span class="docs-why-state accent">aws_vpc.main</span></div></div>
<span class="docs-why-arrow">&rarr;</span>
<div class="docs-why-panel bad"><p class="docs-why-label">Blast radius</p><div class="docs-why-states"><span class="docs-why-state fail">aws_subnet.public</span><span class="docs-why-state fail">aws_subnet.private</span><span class="docs-why-state fail">aws_security_group.web</span><span class="docs-why-state fail">aws_instance.web</span><span class="docs-why-state fail">aws_db_subnet_group.main</span><span class="docs-why-state fail">aws_rds_cluster.database</span></div><p class="docs-why-foot">Each can need an update or a replacement.</p></div>
</div>
<figcaption>A change to <code>aws_vpc.main</code>.<br> Its blast radius holds six resources: two subnets, a security group, an instance, a DB subnet group, and an RDS cluster.</figcaption>
</figure>

## Get the blast radius

In the console, Blast Radius is under **Insights**.

### CLI

1. Get your tenant ID:

```bash
# List your tenants
stategraph user tenants list
```

Output:

```
id                                    name
------------------------------------  ------
550e8400-e29b-41d4-a716-446655440000  my-org
```

2. Get the state ID:

```bash
# List states for a tenant
stategraph states list --tenant 550e8400-e29b-41d4-a716-446655440000 --format json
```

Output:

```json
{
  "results": [
    {
      "created_at": "2024-01-15T10:30:00Z",
      "group_id": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
      "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "name": "networking",
      "workspace": "production"
    }
  ]
}
```

3. Query the blast radius:

```bash
# For aws_instance.web
stategraph states instances blast-radius \
  --state a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
  "aws_instance.web"

# For module.vpc.aws_subnet.public[0]
stategraph states instances blast-radius \
  --state a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
  "module.vpc.aws_subnet.public[0]"
```

Output:

```
address             kind      state       instances  depends_on
------------------  --------  ----------  ---------  ----------
* aws_instance.web  resource  networking  1          0
aws_eip.web         resource  networking  1          1
```

## Read the results

The table has one row for each block of the configuration that the change reaches, nearest first:

- `address`: the block address. `* ` marks the block of the queried instance.
- `kind`: the block type, for example `resource`, `data`, `module`, `variable`, `output`, or `locals`.
- `state`: the state of the block. The blast radius can span states, so this can differ from the queried state.
- `instances`: the number of instances of the block.
- `depends_on`: how many of the listed blocks it depends on.

`--format json` returns the graph: `nodes`, the `edges` between them, `root_id` (the queried block), `total_nodes`, and `truncated`.

`--max-depth` caps the dependency hops (default `100`), and `--limit` caps the blocks (default `1000`). When a cap cuts the result, the CLI prints a warning to stderr.

A change certainly affects the blocks one hop away, and likely affects the blocks two or three hops away. Blocks four or more hops away can be affected, depending on the change type.

## High-risk patterns

### Network foundation resources

VPCs, subnets, and security groups often have a large blast radius:

<figure class="docs-figure">
<div class="docs-why-panel docs-diagram-fit">
<div class="docs-diagram-tree"><span class="docs-why-state accent">aws_vpc.main</span><ul><li><span class="docs-why-state fail">aws_subnet.public</span><span class="docs-diagram-note">20+ resources</span></li><li><span class="docs-why-state fail">aws_subnet.private</span><span class="docs-diagram-note">30+ resources</span></li><li><span class="docs-why-state fail">aws_security_group.web</span><span class="docs-diagram-note">15+ resources</span></li><li><span class="docs-why-state fail">aws_internet_gateway.main</span><span class="docs-diagram-note">10+ resources</span></li></ul></div>
</div>
<figcaption>The subnets, the security group, and the internet gateway of <code>aws_vpc.main</code>.<br> Each has 10 or more resources of its own in the blast radius.</figcaption>
</figure>

### IAM roles

Roles that many services use:

<figure class="docs-figure">
<div class="docs-why-panel docs-diagram-fit">
<div class="docs-diagram-tree"><span class="docs-why-state accent">aws_iam_role.application</span><ul><li><span class="docs-why-state fail">aws_lambda_function.api</span><span class="docs-diagram-note">distance 1</span></li><li><span class="docs-why-state fail">aws_ecs_task_definition.worker</span><span class="docs-diagram-note">distance 1</span></li><li><span class="docs-why-state fail">aws_codebuild_project.build</span><span class="docs-diagram-note">distance 1</span></li><li><span class="docs-why-state more">many more</span></li></ul></div>
</div>
<figcaption>The services that use <code>aws_iam_role.application</code>, each at distance 1 from the role.</figcaption>
</figure>

### Data resources

Databases and storage that services depend on:

<figure class="docs-figure">
<div class="docs-why-panel docs-diagram-fit">
<div class="docs-diagram-tree"><span class="docs-why-state accent">aws_rds_cluster.main</span><ul><li><span class="docs-why-state fail">aws_rds_cluster_instance.primary</span></li><li><span class="docs-why-state fail">aws_rds_cluster_instance.replica</span></li><li><span class="docs-why-state fail">aws_secretsmanager_secret.db_credentials</span></li><li><span class="docs-why-state fail">aws_lambda_function.processor</span></li></ul></div>
</div>
<figcaption>The cluster instances, the credentials secret, and the function that depend on <code>aws_rds_cluster.main</code>.</figcaption>
</figure>

## Reduce the blast radius

For loose coupling, use data sources instead of direct references:

```hcl
# Higher coupling (larger blast radius)
resource "aws_instance" "web" {
  subnet_id = aws_subnet.main.id
}

# Lower coupling
data "aws_subnet" "main" {
  tags = { Name = "main" }
}

resource "aws_instance" "web" {
  subnet_id = data.aws_subnet.main.id
}
```

Put related resources behind a module boundary:

```hcl
module "networking" {
  source = "./modules/networking"
}

module "compute" {
  source    = "./modules/compute"
  subnet_id = module.networking.subnet_id  # Single connection point
}
```

Split large states into smaller, focused states:

```
networking/  → VPCs, subnets, security groups
compute/     → EC2 instances, ASGs
data/        → RDS, DynamoDB
```

## Comparing blast radius

Compare the blast radius of resources to set change priorities:

| Resource | Blast radius size | Risk level |
|----------|------------------|------------|
| aws_vpc.main | 45 resources | High |
| aws_security_group.web | 12 resources | Medium |
| aws_instance.worker | 2 resources | Low |

The same resource can have a different blast radius in each workspace:

| Workspace | aws_vpc.main blast radius |
|-----------|--------------------------|
| Production | 150 resources |
| Staging | 50 resources |
| Dev | 10 resources |

## SQL queries

### Find resources with large blast radius

Blast radius takes one CLI call per resource. A script can loop over all instances:

```bash
#!/bin/bash
STATE_ID="a1b2c3d4-e5f6-7890-abcd-ef1234567890"

# Get all instance addresses (--paginate needs the ORDER BY to read every page)
stategraph sql query --paginate --format json \
  "SELECT address FROM instances WHERE state_id = '$STATE_ID' ORDER BY address" | \
  jq -r '.[].address' | while read -r instance; do
    count=$(stategraph states instances blast-radius --state "$STATE_ID" --format json "$instance" 2>/dev/null | \
      jq '[.nodes[] | select(.is_seed | not)] | length')
    printf '%s\t%s\n' "$count" "$instance"
done | sort -rn | head -20
```

### Find highly connected resources

Instances that depend on the most resources:

```sql
SELECT address, array_length(dependencies, 1::integer) as dep_count
FROM instances
WHERE array_length(dependencies, 1::integer) > 0
ORDER BY array_length(dependencies, 1::integer) DESC
LIMIT 20
```

## Best practices

- Before you change critical infrastructure, apply a production change, or start maintenance, check the blast radius of each component and whether changes cascade to critical services.
- Plan the change window from the impact. Plan communication and a rollback in case the blast radius was underestimated.
- Mark resources with a large blast radius as high risk, and take extra care with their changes.
- Prefer several small changes to one large change.
- Test in staging, to make sure that changes do not cascade unexpectedly.

## Limitations

- Blast radius shows structural dependencies, not runtime dependencies.
- It does not track external dependencies, such as DNS or external APIs.
- Changes that do not affect the dependency graph can still cause problems.

## Next steps

- [Graph Explorer](/docs/infrastructure-as-a-database/query/graph-explorer): see the dependencies.
- [Timeline](/docs/infrastructure-as-a-database/query/timeline): follow changes.
- [Query](/docs/infrastructure-as-a-database/query/query): query with SQL.
