---
title: Reference
description: Find the exact syntax for Stategraph: the configuration file, pull request commands, the CLI, the API, and the SQL language.
order: 1
---


The reference gives the exact syntax of the Orchestration configuration file and pull request commands, the `stategraph` CLI, the Stategraph API, and the SQL language.

## Configuration reference

Stategraph Orchestration reads its configuration from `.stategraph/config.yml`. Each page has defaults and examples:

- [access_control](/docs/reference/orchestration/configuration/access-control): who can run plan, apply, and the other commands
- [apply_requirements](/docs/reference/orchestration/configuration/apply-requirements): what a pull request must meet before an apply runs
- [automerge](/docs/reference/orchestration/configuration/automerge): merge the pull request after all directories apply
- [batch_runs](/docs/reference/orchestration/configuration/batch-runs): the maximum number of workspaces per CI run
- [config_builder](/docs/reference/orchestration/configuration/config-builder): generate the configuration at runtime with a script
- [cost_estimation](/docs/reference/orchestration/configuration/cost-estimation): cost estimates with plan output
- [default_branch_overrides](/docs/reference/orchestration/configuration/default-branch-overrides): which keys Orchestration reads from the default branch
- [definitions](/docs/reference/orchestration/configuration/definitions): YAML anchors for reusable configuration
- [destination_branches](/docs/reference/orchestration/configuration/destination-branches): which target branches start runs
- [dirs](/docs/reference/orchestration/configuration/dirs): tags, workspaces, and when-modified rules per directory
- [drift](/docs/reference/orchestration/configuration/drift): drift detection and reconciliation schedules
- [enabled](/docs/reference/orchestration/configuration/enabled): turn Orchestration on or off for a repository
- [engine](/docs/reference/orchestration/configuration/engine): the tool that runs plan and apply, and its version
- [hooks](/docs/reference/orchestration/configuration/hooks): commands and environment variables before and after workflows
- [Ignoring a directory](/docs/reference/orchestration/configuration/ignore-patterns): directories and files that never plan or apply
- [indexer](/docs/reference/orchestration/configuration/indexer): generate configuration from a repository analysis
- [lock_policy](/docs/reference/orchestration/configuration/lock-policy): when Orchestration locks a directory and workspace
- [notifications](/docs/reference/orchestration/configuration/notifications): what Orchestration posts back to the pull request
- [parallel_runs](/docs/reference/orchestration/configuration/parallel-runs): how many runs execute concurrently
- [stacks](/docs/reference/orchestration/configuration/stacks): named groups of dirspaces with shared configuration and ordering
- [storage](/docs/reference/orchestration/configuration/storage): where Orchestration stores plan files
- [Tag queries](/docs/reference/orchestration/configuration/tag-queries): the query language that matches directories and workspaces
- [tags](/docs/reference/orchestration/configuration/tags): custom labels for matching and filtering
- [tree_builder](/docs/reference/orchestration/configuration/tree-builder): a custom script that defines the file tree and what changed
- [version](/docs/reference/orchestration/configuration/version): the configuration file format version
- [when_modified](/docs/reference/orchestration/configuration/when-modified): autoplan and autoapply on file changes
- [workflows](/docs/reference/orchestration/configuration/workflows): the steps of a plan or apply

## Pull request commands

Commands are pull request comments that start with `stategraph`:

- [stategraph help](/docs/reference/orchestration/commands/help): list the available commands
- [stategraph plan](/docs/reference/orchestration/commands/plan): plan the changed directories, or those that match a tag query
- [stategraph apply](/docs/reference/orchestration/commands/apply): apply the stored plans
- [stategraph apply-autoapprove](/docs/reference/orchestration/commands/apply-autoapprove): plan and apply in one step
- [stategraph apply-force](/docs/reference/orchestration/commands/apply-force): apply without meeting the apply requirements
- [stategraph unlock](/docs/reference/orchestration/commands/unlock): release the locks of a pull request
- [stategraph gate approve](/docs/reference/orchestration/commands/gate-approve): approve a gated workflow step
- [stategraph repo-config](/docs/reference/orchestration/commands/repo-config): print the evaluated repository configuration
- [stategraph feedback](/docs/reference/orchestration/commands/feedback): send feedback from the pull request

## CLI reference

The `stategraph` CLI imports state, plans and applies with Infrastructure as a Database, and queries your infrastructure. Start with [CLI reference](/docs/cli) for installation and the common options.

- [User](/docs/cli/user): identity and tenant membership
- [Capabilities](/docs/cli/capabilities): the default capability set and per-group capability rules
- [Import](/docs/cli/import): one-step state and HCL import
- [States](/docs/cli/states): create, list, import, export, query, and blast radius
- [Terraform](/docs/cli/tf): `tf plan`, `tf apply`, `tf show`, and `tf mtx` for multi-state transactions
- [Refactor](/docs/cli/refactor): detect and apply HCL refactors
- [Transactions](/docs/cli/transactions): transaction commands, including plan-time costs
- [SQL](/docs/cli/sql): query commands and schema discovery
- [Tenant](/docs/cli/tenant): gap analysis for unmanaged resources
- [Cost](/docs/cli/cost): state and tenant cost, attribution, history, and billing sources
- [Security](/docs/cli/security): scan history, findings, severity rollup, transaction impact, and re-scan
- [HCL](/docs/cli/hcl): list addresses, evaluate expressions, convert HCL and JSON
- [Diagnostics](/docs/cli/diagnostics): trace how your HCL evaluates locally
- [Config](/docs/cli/config): `stategraph.json` attached files and ephemeral tfvars
- [Utilities](/docs/cli/utilities): `info` and `version`

## API

The [Stategraph API](/docs/reference/api) is the REST API of Orchestration and Infrastructure as a Database. The overview covers the base URL, authentication, pagination, and errors. Each resource has its own page: users, user management, tenants, API keys, states, transactions, queries, cost, security, VCS installations, stacks, the key-value store, and the server.

Common endpoints:

- `GET /api/v1/whoami`: current user information
- `GET /api/v1/mql`: run an SQL query
- `GET /api/v1/tenants/{tenant_id}/states`: list states
- `GET /api/v1/states/{state_id}/instances`: list resource instances
- `GET /api/v1/states/{state_id}/costs`: cost snapshot of a state
- `GET /api/v1/openapi`: the OpenAPI schema

## Other reference pages

- [Terraform CLI Compatibility](/docs/reference/terraform-compatibility): how Terraform CLI commands and HCL constructs map to Stategraph
- [SQL Syntax](/docs/reference/sql-syntax): the grammar of the query language
- [Troubleshooting](/docs/reference/troubleshooting): common problems and their solutions
- [Releases and Downloads](/docs/reference/releases): Docker images, binaries, and version history

## Quick links

### Common environment variables

Required:

```bash
STATEGRAPH_UI_BASE=https://stategraph.example.com
DB_HOST=postgres
DB_USER=stategraph
DB_PASS=password
DB_NAME=stategraph
```

Optional:

```bash
STATEGRAPH_OAUTH_TYPE=google
```

For all variables, see [Environment variables](/docs/admin/operations/environment-variables).

### SQL quick reference

Basic query:

```sql
SELECT * FROM resources WHERE type = 'aws_instance'
```

Aggregation:

```sql
SELECT type, count(*) FROM resources GROUP BY type ORDER BY type
```

JSON access:

```sql
SELECT attributes->>'instance_type' FROM instances
```

See [SQL Syntax](/docs/reference/sql-syntax).
