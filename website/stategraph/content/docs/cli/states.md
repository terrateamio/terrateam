---
title: States Commands
description: CLI commands for Terraform states in Stategraph: create, import, export, list, inspect, query, and delete states.
order: 2
---


The `stategraph states` commands create, import, export, list, inspect, and delete the Terraform states in Stategraph. They also resolve state IDs and anonymize state files.

## Commands

| Command | Description |
|---------|-------------|
| `stategraph states create` | Create an empty state |
| `stategraph states delete` | Delete a state permanently |
| `stategraph states list` | List the states of a tenant |
| `stategraph states resolve` | Get a state ID from a workspace or a name |
| `stategraph states import` | Import a Terraform state file |
| `stategraph states export` | Export a Terraform state file |
| `stategraph states summary` | Count edges, instances, modules, providers, and resources |
| `stategraph states resources summary` | Count instances per resource type |
| `stategraph states instances` | Blast radius and queries of instances |
| `stategraph states modules list` | List the modules of a state |
| `stategraph states anonymize` | Anonymize a Terraform state JSON file, locally |

Common options:

- `--tenant` takes a tenant ID, and `--state` takes a state ID. Both are UUIDs.
- Both are required, except `--state` on `delete`, `resolve`, and `export`. There, the default is read from `stategraph.json`.
- `--workspace` takes a workspace name. Default: `default`.

## stategraph states create

```bash
stategraph states create --tenant <tenant-id> --name <state-name> [options]
```

### Options

| Option | Required | Description |
|--------|----------|-------------|
| `--tenant` | Yes | Tenant ID (UUID) |
| `--name` | Yes | Name for the state |
| `--group` | No | Group ID for the state |
| `--workspace` | No | Workspace name |
| `--no-write-config` | No | Do not write `stategraph.json` |
| `--silent` | No | Suppress prompt output |

By default, the command writes `stategraph.json` to the current directory. The file binds the directory to the new state, so later commands find it. Commit the file, or add `--no-write-config`.

### Example

```bash
stategraph states create --tenant 550e8400-e29b-41d4-a716-446655440000 --name "networking"
```

Output (JSON):

```json
{
  "id": "...",
  "name": "networking",
  "group_id": "...",
  "workspace": "default",
  "created_at": "2024-01-15T10:30:00Z"
}
```

## stategraph states delete

`delete` removes the state and all of its data. This includes resources, instances, providers, outputs, HCL, files, tfvars, transaction logs, check entries and results, cost snapshots, security scans, and their schedules. You cannot undo it.

```bash
stategraph states delete --state <state-id>
```

### Options

| Option | Required | Description |
|--------|----------|-------------|
| `--state` | No | State ID to delete |
| `--workspace` | No | Workspace name, to find the state in `stategraph.json` |
| `--auto-approve` | No | Skip the confirmation prompt, for scripts and CI. Without it, the command asks for confirmation. Without a terminal, it aborts. |

You need admin rights on the tenant of the state, or on the whole installation. Without them, or when the state does not exist, the command returns an error.

### Examples

With the confirmation prompt:

```bash
stategraph states delete --state 550e8400-e29b-41d4-a716-446655440000
```

Without a prompt, for example in CI:

```bash
stategraph states delete --state 550e8400-e29b-41d4-a716-446655440000 --auto-approve
```

## stategraph states list

```bash
stategraph states list --tenant <tenant-id>
```

### Example

```bash
stategraph states list --tenant 550e8400-e29b-41d4-a716-446655440000
```

The default output is a table with `id`, `name`, `workspace`, `group_id`, and `created_at`. With `--format json`:

```json
{
  "results": [
    {
      "created_at": "2024-01-15T10:30:00Z",
      "group_id": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
      "id": "...",
      "name": "networking",
      "workspace": "production"
    }
  ]
}
```

## stategraph states resolve

`resolve` prints a state ID, for scripts that must not hardcode it.

```bash
stategraph states resolve [options]
```

### Options

| Option | Required | Description |
|--------|----------|-------------|
| `--name` | No | Resolve by state name. Ignores `stategraph.json` and `--workspace`. |
| `--state` | No | State ID or group ID |
| `--workspace` | No | Workspace name |
| `--group` | No | Print the group ID, not the state ID |

### Examples

By workspace, with `stategraph.json`:

```bash
stategraph states resolve --workspace staging
```

By name:

```bash
stategraph states resolve --name networking
```

The group ID:

```bash
stategraph states resolve --group
```

## stategraph states export

`export` prints the state as Terraform state JSON. It takes `--state` and `--workspace`.

```bash
stategraph states export [options]
```

### Example

```bash
stategraph states export --workspace production > terraform.tfstate
```

## stategraph states import

```bash
stategraph states import --tenant <tenant-id> --name <state-name> [options] <state-file>
```

### Options

| Option | Required | Description |
|--------|----------|-------------|
| `--tenant` | Yes | Tenant ID (UUID) |
| `--name` | Yes | Name for the state |
| `--group` | No | Group ID for the state |
| `--workspace` | No | Workspace name |
| `--tag` | No | Tag as `key=value`. Repeatable. |
| `--tags` | No | Tags as a JSON object |
| `-y` | No | Answer yes to prompts (or set `STATEGRAPH_NON_INTERACTIVE`) |
| `--silent` | No | Suppress prompt output. Only effective with `-y`. |

### Example

```bash
# Import with tags
stategraph states import \
  --tenant 550e8400-e29b-41d4-a716-446655440000 \
  --name "networking" \
  --workspace "production" \
  --tag environment=prod \
  --tag team=platform \
  terraform.tfstate
```

## stategraph states summary

```bash
stategraph states summary --state <state-id>
```

### Example

```bash
stategraph states summary --state 550e8400-e29b-41d4-a716-446655440000
```

Output (table):

```text
Edges       234
Instances   150
Modules     8
Providers   3
Resources   45
```

## stategraph states resources summary

```bash
stategraph states resources summary --state <state-id>
```

### Example

```bash
stategraph states resources summary --state 550e8400-e29b-41d4-a716-446655440000
```

Output (table):

```text
aws_instance          20
aws_security_group    15
aws_subnet            6
aws_iam_role          12
```

## stategraph states instances

### stategraph states instances blast-radius

Lists every HCL block that a change to the instance reaches. The analysis follows the dependency graph of the Terraform configuration across linked states, so results can be in another state. `stategraph blast-radius` is an alias.

```bash
stategraph states instances blast-radius --state <state-id> <instance-address>
```

#### Example

```bash
stategraph states instances blast-radius \
  --state 550e8400-e29b-41d4-a716-446655440000 \
  "aws_vpc.main"
```

Output (table):

```text
address                 kind      state       instances  depends_on
----------------------  --------  ----------  ---------  ----------
* aws_vpc.main          resource  networking  1          0
aws_security_group.web  resource  networking  1          1
aws_subnet.public_a     resource  networking  1          1
aws_subnet.public_b     resource  networking  1          1
aws_instance.web        resource  networking  1          2
```

- `*` marks the block of the queried instance. The nearest blocks come first.
- `kind` is the HCL block type, and `state` is the name of the state that holds the block.
- `instances` is the instance count of the block. `depends_on` counts its dependencies among the listed blocks.
- `--format json` also returns the edges.
- `--max-depth` (default and maximum 100) and `--limit` (default and maximum 1000) cap the graph. When they cut it, the CLI prints a warning to stderr.

For the console view, see [Blast radius](/docs/infrastructure-as-a-database/query/blast-radius).

### stategraph states instances query

The query is a filter of `key:value` terms, for example `type:aws_instance` or `module:module.app`.

- The keys are `type`, `module`, `provider`, `address`, and `resource_address`. `attr:<name>:<value>` matches a top-level string attribute.
- Terms separated by a space must all match. `and`, `or`, `not`, and parentheses combine terms.

```bash
stategraph states instances query --state <state-id> [-i] <query>
```

`-i` reads all pages of the result.

#### Example

```bash
stategraph states instances query \
  --state 550e8400-e29b-41d4-a716-446655440000 \
  "type:aws_instance"
```

## stategraph states modules list

```bash
stategraph states modules list --state <state-id>
```

### Example

```bash
stategraph states modules list --state 550e8400-e29b-41d4-a716-446655440000
```

Output (table):

```text
module.vpc           10    25
module.eks           8     45
module.rds           4     12
```

Columns: `module`, `resource_count`, `instance_count`.

## stategraph states anonymize

`anonymize` prints an anonymized copy of a Terraform state JSON file, so you can share it for debugging or support without real values. It runs locally and does not contact the server.

```bash
stategraph states anonymize <state-file> [--seed <n>]
```

### Options

| Option | Required | Description |
|--------|----------|-------------|
| `<state-file>` | Yes | Path to a Terraform state JSON file |
| `-s`, `--seed` | No | Seed for deterministic anonymization |

### Example

```bash
stategraph states anonymize terraform.tfstate --seed 42 > anonymized.tfstate
```

## Scripting Examples

### Summarize every state

```bash
stategraph states list --tenant $TENANT_ID --format json | jq -r '.results[] | .id' | while read state_id; do
  echo "Exporting $state_id..."
  stategraph states summary --state "$state_id"
done
```

### Find states with specific resource types

```bash
stategraph states list --tenant $TENANT_ID --format json | jq -r '.results[] | .id' | while read state_id; do
  count=$(stategraph states resources summary --state "$state_id" 2>/dev/null | grep aws_rds_cluster | awk '{print $2}')
  if [ -n "$count" ] && [ "$count" -gt 0 ]; then
    echo "State $state_id has $count RDS clusters"
  fi
done
```

## Next Steps

- [Import Commands](/docs/cli/import): onboard a state and its HCL in one step.
- [Transactions](/docs/cli/transactions): manage transactions.
- [SQL](/docs/cli/sql): query infrastructure.
