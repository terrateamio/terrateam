---
title: Graph Explorer
description: See one resource and every block that a change to it reaches as an interactive dependency graph, across modules and linked states.
order: 12
---


Graph Explorer draws one resource instance and every block that a change to it reaches, as an interactive graph. The graph follows references into modules and linked states.

In the console, Graph Explorer is under **Insights**.

## How dependencies work

A reference from one block to another creates a dependency. Terraform orders its operations by these dependencies.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.main.id  # Creates dependency
}
```

A chain of references makes a chain of dependencies:

```hcl
resource "aws_security_group" "web" {
  vpc_id = aws_vpc.main.id  # Depends on VPC
}

resource "aws_instance" "web" {
  security_groups = [aws_security_group.web.id]  # Depends on SG
}
```

Dependencies form a directed acyclic graph (DAG):

<figure class="docs-figure">
<div class="docs-why-panel docs-diagram-fit">
<svg class="docs-diagram-graph" width="314" height="144" viewBox="0 0 314 144" role="img" aria-label="Dependency graph. aws_subnet.public and aws_security_group.web depend on aws_vpc.main. aws_instance.web depends on both of them."><path d="M149 27V43"/><path d="M67 59V43H231V59"/><path d="M67 85V101H231V85"/><path d="M149 101V117"/><g class="accent"><rect x="98" y="1" width="102" height="26" rx="4"/><text x="149" y="14">aws_vpc.main</text></g><g><rect x="1" y="59" width="132" height="26" rx="4"/><text x="67" y="72">aws_subnet.public</text></g><g><rect x="149" y="59" width="164" height="26" rx="4"/><text x="231" y="72">aws_security_group.web</text></g><g><rect x="86" y="117" width="126" height="26" rx="4"/><text x="149" y="130">aws_instance.web</text></g></svg>
</div>
<figcaption><code>aws_subnet.public</code> and <code>aws_security_group.web</code> depend on <code>aws_vpc.main</code>.<br> <code>aws_instance.web</code> depends on both.</figcaption>
</figure>

The graph has an edge for each reference to a value, each read of a file or a tfvar, and each module call that fills a child module variable. A `depends_on` has no edge, because a change does not travel along it.

## Scoping the graph

Graph Explorer shows the graph around one instance, not the full state. If the root has more than 40 direct dependents or the graph has more than 50 nodes, Graph Explorer does not draw it. For a larger graph, use [Blast Radius](/docs/infrastructure-as-a-database/query/blast-radius).

## Understanding the visualization

| Element | Meaning |
|---------|---------|
| Root node | The selected instance, larger and in the accent color |
| Rectangle | A resource, a data source (dashed border), or a module call |
| Pill | A local value, a variable, or an output |
| Node label | Block address |
| Arrow | A → B means that B depends on A |
| Dashed edge | A module call that fills a child module variable |

Hover over a node to highlight its direct dependencies (blue edges) and direct dependents (purple edges). The hierarchical layout (dagre) puts nodes in dependency tiers, from top to bottom. Edges go in one direction, and related blocks stay near their dependencies.

## Common patterns

### Hub resources

A hub has many dependents:

<figure class="docs-figure">
<div class="docs-why-panel docs-diagram-fit">
<div class="docs-diagram-tree"><span class="docs-why-state accent">aws_vpc.main</span><ul><li><span class="docs-why-state fail">aws_instance.web1</span></li><li><span class="docs-why-state fail">aws_instance.web2</span></li><li><span class="docs-why-state fail">aws_rds_cluster.db</span></li></ul></div>
<p class="docs-why-foot">Three dependents.</p>
</div>
<figcaption>A hub: <code>aws_instance.web1</code>, <code>aws_instance.web2</code>, and <code>aws_rds_cluster.db</code> depend on <code>aws_vpc.main</code>.</figcaption>
</figure>

A change to a hub affects many resources. Use [Blast Radius](/docs/infrastructure-as-a-database/query/blast-radius) to see the impact.

### Leaf resources

A leaf has no dependents:

<figure class="docs-figure">
<div class="docs-why-panel docs-diagram-fit">
<div class="docs-diagram-tree"><span class="docs-why-state">aws_security_group.web</span><ul><li><span class="docs-why-state accent">aws_instance.web</span><span class="docs-diagram-note">leaf</span></li></ul></div>
<p class="docs-why-foot">No dependents.</p>
</div>
<figcaption><code>aws_instance.web</code> depends on <code>aws_security_group.web</code>.<br> Nothing depends on <code>aws_instance.web</code>, so it is a leaf.</figcaption>
</figure>

A leaf is safer to change: it has fewer downstream effects.

### Module clusters

The resources of a module form a cluster:

<figure class="docs-figure">
<div class="docs-why-panel docs-diagram-fit">
<div class="docs-diagram-row"><div class="docs-diagram-group"><span class="docs-diagram-note">module.vpc</span><div class="docs-diagram-row"><span class="docs-why-state">vpc</span><span class="docs-diagram-edge"></span><span class="docs-why-state">subnet</span></div></div><span class="docs-why-arrow">&rarr;</span><div class="docs-diagram-group"><span class="docs-diagram-note">module.compute</span><div class="docs-diagram-row"><span class="docs-why-state">instance</span></div></div></div>
</div>
<figcaption>Two clusters: the vpc and the subnet of <code>module.vpc</code>, and the instance of <code>module.compute</code>.<br> <code>module.compute</code> depends on <code>module.vpc</code>.</figcaption>
</figure>

## Use cases

- Architecture: find the major resource groups and follow the data flow.
- Change planning: see the dependents of a resource before you change it.
- Documentation: frame a root, then take a screenshot.
- Debugging: see the dependencies that set the order of operations.
- Comparison: view the graphs of different workspaces side by side.

## CLI access

### Get instances with dependencies

`stategraph states instances query` returns the dependencies that the state records. The `QUERY` argument is a filter of space-separated `key:value` terms (`type`, `module`, `provider`, `address`, `resource_address`, `attr:<key>:<value>`). `-i` gets every page:

```bash
stategraph states instances query \
  --state a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
  --format json \
  -i "type:aws_instance"
```

The response includes the dependencies:

```json
{
  "results": [
    {
      "address": "aws_instance.web",
      "type": "aws_instance",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "dependencies": [
        "aws_subnet.main",
        "aws_security_group.web"
      ]
    }
  ]
}
```

### Query dependencies with SQL

Find all dependencies of a resource:

```sql
SELECT dependencies FROM instances
WHERE address = 'aws_instance.web'
```

Find resources that depend on a specific resource:

```sql
SELECT address FROM instances
WHERE to_jsonb(dependencies) @> '["aws_vpc.main"]'::jsonb
```

## Next steps

- [Blast Radius](/docs/infrastructure-as-a-database/query/blast-radius): detailed impact analysis.
- [Search](/docs/infrastructure-as-a-database/query/search): find resources quickly.
- [Query](/docs/infrastructure-as-a-database/query/query): query dependencies with SQL.
