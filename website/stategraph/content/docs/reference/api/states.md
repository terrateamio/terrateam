---
title: States
description: API endpoints that create, import, export, and delete states, serve the Terraform HTTP backend, and read instances, modules, and summaries.
order: 6
---


These endpoints create, import, export, and delete states, serve the Terraform HTTP backend, and read the instances, blast radius, modules, and summaries of states.

## States

### List states

```text
GET /api/v1/tenants/{tenant_id}/states
```

Returns all states of a tenant.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `tenant_id` | path | Yes | Tenant ID |
| `page` | query | No | Pagination cursor |
| `limit` | query | No | Max results (default: 100) |
| `q` | query | No | Accepted, but the server ignores it |
| `tz` | query | No | Accepted, but the server ignores it |

Response:

```json
{
  "results": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "networking",
      "group_id": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
      "workspace": "default",
      "created_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

### Create state

```text
POST /api/v1/tenants/{tenant_id}/states
```

Creates a state.

Request body:

```json
{
  "name": "networking",
  "group_id": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
  "workspace": "production"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | State name |
| `group_id` | uuid | No | Group identifier (UUID; defaults to a generated UUID) |
| `workspace` | string | No | Workspace name (default: `default`) |

Response: `201 Created` with the state object.

### Import state

```text
POST /api/v1/tenants/{tenant_id}/states/import
```

Imports an existing Terraform state file.

Request body:

```json
{
  "name": "networking",
  "group_id": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
  "workspace": "production",
  "state": { ... },
  "tags": { "source": "migration" }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | State name |
| `state` | object | Yes | Terraform state JSON |
| `group_id` | uuid | No | Group identifier (UUID; defaults to a generated UUID) |
| `workspace` | string | No | Workspace name |
| `tags` | object | No | Metadata tags |

### Export state

```text
GET /api/v1/states/{state_id}/export
```

Returns the full Terraform state as JSON, like `terraform state pull` and `stategraph states export`.

```bash
curl "$STATEGRAPH_API_BASE/api/v1/states/$STATE_ID/export" \
  -H "Authorization: Bearer $STATEGRAPH_API_KEY"
```

### Delete state

```text
DELETE /api/v1/states/{state_id}
```

Permanently deletes a state and all its related data: resources, instances, providers, outputs, raw states, transaction logs, and check entries and results. You cannot undo this. Requires admin privileges.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `state_id` | path | Yes | State ID (UUID) |

Response codes:

| Code | Description |
|------|-------------|
| `200 OK` | State deleted |
| `401 Unauthorized` | Not authenticated |
| `403 Forbidden` | User is not an admin |
| `404 Not Found` | State does not exist |
| `500 Internal Server Error` | Server error |

Example:

```bash
curl -X DELETE "$STATEGRAPH_API_BASE/api/v1/states/550e8400-e29b-41d4-a716-446655440000" \
  -H "Authorization: Bearer $STATEGRAPH_API_KEY"
```

Error response (403 Forbidden):

```json
{
  "id": "ADMIN_REQUIRED",
  "data": "Admin privileges required"
}
```

Error response (404 Not Found):

```json
{
  "id": "STATE_NOT_FOUND",
  "data": "State not found"
}
```

### Terraform HTTP backend

```text
GET  /api/v1/states/backend/{group_id}
POST /api/v1/states/backend/{group_id}
GET  /api/v1/states/backend/{group_id}/{workspace}
POST /api/v1/states/backend/{group_id}/{workspace}
```

Reads or writes the Terraform state document of a state, by group ID and workspace. `GET` returns the document as JSON. `POST` stores the request body as the new state. Without a workspace segment, the path addresses the `default` workspace.

### Revision endpoints

```text
POST /api/v1/states/{state_id}/revision
POST /api/v1/states/{state_id}/revision/compare
POST /api/v1/states/{state_id}/revision/hash
```

The CLI uses these to record and compare per-node revision hashes for a state in a transaction:

- `revision` takes `{ "tx_id", "nodes": [{ "key", "hash" }] }`.
- `compare` takes `{ "tx_id" }` and returns `node_ids`.
- `hash` returns the current `hash` of the state, or `404` when there is none.

## Instances and modules

### List instances

```text
GET /api/v1/states/{state_id}/instances
```

Returns the resource instances of a state.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `state_id` | path | Yes | State ID |
| `page` | query | No | Pagination cursor |
| `limit` | query | No | Max results |
| `q` | query | No | Filter of space-separated `key:value` terms. Keys: `address`, `resource_address`, `module`, `provider`, `type`, and `attr:<key>:<value>`. Example: `type:aws_instance` |
| `tz` | query | No | Accepted, but the server ignores it |

Response:

```json
{
  "results": [
    {
      "address": "aws_instance.web",
      "type": "aws_instance",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "module": null,
      "attributes": { ... },
      "dependencies": ["aws_subnet.main", "aws_security_group.web"]
    }
  ]
}
```

### Get blast radius

```text
GET /api/v1/states/{state_id}/instances/{instance_address}/blast-radius
```

Returns the resources that a change to the instance affects. The analysis follows the dependency graph of the Terraform configuration across linked states. A result can belong to a state other than the one in the path.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `state_id` | path | Yes | State ID |
| `instance_address` | path | Yes | URL-encoded instance address |

Response:

```json
{
  "results": [
    {
      "address": "aws_instance.web",
      "resource_address": "aws_instance.web",
      "direction": "seed",
      "distance": 0,
      "state_id": "550e8400-e29b-41d4-a716-446655440000",
      "state_name": "networking"
    },
    {
      "address": "aws_eip.web",
      "resource_address": "aws_eip.web",
      "direction": "blast",
      "distance": 1,
      "state_id": "550e8400-e29b-41d4-a716-446655440000",
      "state_name": "networking"
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `address` | string | Instance address |
| `resource_address` | string | Resource address the instance belongs to |
| `direction` | enum | `seed` for the selected resource, `blast` for a dependent it would affect |
| `distance` | integer | Number of dependency edges from the seed |
| `index` | string or integer | Instance index for `count` and `for_each` resources (optional) |
| `state_id` | string | State the instance lives in |
| `state_name` | string | Name of that state (optional) |

### List modules

```text
GET /api/v1/states/{state_id}/modules
```

Returns the modules in a state.

Response:

```json
{
  "results": [
    {
      "name": "module.vpc",
      "instance_count": 25,
      "resource_count": 10
    }
  ]
}
```

## Summaries

### State summary

```text
GET /api/v1/states/{state_id}/summary
```

Returns aggregate statistics for a state.

Response:

```json
{
  "instances": 150,
  "resources": 45,
  "modules": 8,
  "providers": 3,
  "edges": 234
}
```

### Resources summary

```text
GET /api/v1/states/{state_id}/resources/summary
```

Returns instance counts by resource type.

Response:

```json
{
  "aws_instance": { "instances": 20 },
  "aws_security_group": { "instances": 15 },
  "aws_subnet": { "instances": 6 }
}
```

### Tenant summary

```text
GET /api/v1/tenants/{tenant_id}/summary[?state_id={state_id}]
```

Returns inventory aggregates for a tenant, or for one state with `?state_id`: totals, provider and resource-type distributions, graph structure, largest and most-deployed modules, and orphaned-resource counts.

Response (abridged):

```json
{
  "total_states": 15,
  "total_resources": 1234,
  "total_instances": 1890,
  "total_modules": 42,
  "total_providers": 3,
  "total_edges": 2310,
  "provider_distribution": [],
  "resource_type_distribution": [],
  "top_resource_type": "aws_iam_role",
  "largest_module": "module.vpc",
  "most_deployed_module": "module.service",
  "orphaned_count": 7,
  "graph_roots": 12,
  "graph_leaves": 340
}
```

### Resource types

```text
GET /api/v1/tenants/{tenant_id}/resource-types[?state_id={state_id}]
```

Returns, per state and resource type, the number of declared resources and deployed instances, with tenant totals. Not paginated. `state_id` limits the result to one state. See [Resource types](/docs/infrastructure-as-a-database/query/resource-types).

Response:

```json
{
  "resource_types": [
    {
      "state_id": "550e8400-e29b-41d4-a716-446655440000",
      "state_name": "networking",
      "type": "aws_subnet",
      "resource_count": 3,
      "instance_count": 6
    }
  ],
  "total_resources": 45,
  "total_instances": 150
}
```
