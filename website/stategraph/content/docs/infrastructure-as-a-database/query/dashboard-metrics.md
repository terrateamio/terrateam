---
title: Dashboard metrics
description: Learn what each metric on the console home page means, how Stategraph calculates it, and what to look for in your states.
order: 8
---


The console home page shows metrics from the transactions, the dependency graph, and the state metadata of your tenant. The state filter limits the graph and state metrics to one state. The Control Plane Status metrics always cover the full tenant.

## Control Plane Status

### Active Transactions

The number of Terraform transactions (plans or applies) in progress in the tenant. Zero means that the system is idle.

### Last Transaction

The outcome of the most recent completed transaction, and how long ago it completed.

| Status | Meaning |
|--------|---------|
| Committed | Applied successfully |
| Aborted | Cancelled manually before completion |
| Failed | An error occurred during apply |

### Recent Changes

The count of committed, aborted, and failed transactions in the last 24 hours. It shows how actively your infrastructure changes, and whether failures occur.

### Last Change Impact

The blast radius of the most recent committed transaction: the number of resources that the change affected directly or transitively. A high number means a wide-reaching change. Zero means no recent changes.

## State Structure

### Resources

The number of resource instances. Each maps to one real infrastructure object, for example an S3 bucket or an IAM role.

### Modules

The number of distinct Terraform modules. Modules group related resources into reusable, composable units. A high count can show a well-factored configuration.

### Providers

The number of different cloud or service providers (for example AWS, GCP, or Azure) that the resources use. Multi-provider states have a broader infrastructure scope.

### Graph Density

Dependency edges divided by resources, in edges/resource. A resource with `count` or `for_each` counts once. For example, 50 resources and 75 dependency edges give 1.50 edges/res.

| Value | Interpretation |
|-------|---------------|
| < 1.0 | Sparse: most resources are standalone or have few dependencies. |
| ~1.0 | About one dependency per resource. Common for simple configurations. |
| > 2.0 | Heavily interconnected: changes are more likely to cascade across many resources. |

## Risk and Dependency Analysis

### Largest Dependency Blast Radius

The resource that the most other resources reference directly, with the number of references. It shows the same resource and count as Top Dependency Hotspot, and links to the blast radius of that resource.

### Top Dependency Hotspot

The resource that the most other resources depend on (the highest inbound reference count), so changes to it can cascade widely.

### Graph Structure

- Roots: resources with no dependencies, the entry points of the dependency graph. They are typically foundational resources (VPCs, projects, resource groups).
- Leaves: resources that nothing else depends on, the terminal nodes. They are often end-user-facing resources (DNS records, load balancers).

## Control Plane Insights

The Terraform CLI does not show these metrics.

### Largest Module

The Terraform module with the most resources. Splitting a very large module into smaller, focused units can make it easier to maintain, and isolate its blast radius.

### Most Deployed Module

The module that appears the most times across resource instances. High reuse shows a well-designed shared module. Low reuse with many modules can show duplicated patterns to consolidate.

### Top Resource Type

The Terraform resource type with the most resources, for example `aws_security_group_rule` or `aws_iam_policy`.

### Orphaned Candidates

Resources that graph analysis flags as possibly unused. A resource is a candidate when:

- No other resource depends on it (a leaf node).
- It is outside any module.
- It has at most one dependency.

Modules typically bundle related resources on purpose, so resources in a module are never candidates. Not every candidate is orphaned. Review each one, then remove it or leave it in place.

### Provider Distribution (Chart)

A doughnut chart of the percentage of resources per provider. It shows the top four providers individually, and groups the rest as "Other."

### Top Resource Types (Chart)

A horizontal bar chart of the five most common resource types and their instance counts. A heavily skewed distribution can show repetitive infrastructure, for example many security group rules.

Both charts count every resource instance in the selected states.

## Next steps

- [Blast Radius](/docs/infrastructure-as-a-database/query/blast-radius)
- [Graph Explorer](/docs/infrastructure-as-a-database/query/graph-explorer)
- [Timeline](/docs/infrastructure-as-a-database/query/timeline)
