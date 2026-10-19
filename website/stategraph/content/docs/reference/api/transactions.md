---
title: Transactions and tasks
description: API endpoints that list, create, read, and abort transactions, read their logs, plan operations, and output, and poll long-running tasks.
order: 7
---


These endpoints list, create, read, and abort transactions, read their logs, plan operations, output, and states, and poll the tasks of long-running operations.

## Transactions

### List transactions

```text
GET /api/v1/tenants/{tenant_id}/tx
```

Returns the transactions of a tenant.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `page` | query | No | Pagination cursor |
| `limit` | query | No | Max results |
| `from` | query | No | Only transactions created at or after this ISO 8601 date-time (a bare date is accepted) |
| `to` | query | No | Only transactions created at or before this ISO 8601 date-time (a bare date is accepted) |

Response:

```json
{
  "results": [
    {
      "id": "455fe705-f27f-4335-9355-dbe8f14098df",
      "created_at": "2024-01-15T10:30:00Z",
      "created_by": "f30ed1f9-be44-46a3-9050-03e9561e94f0",
      "created_by_name": "Jane Doe",
      "completed_at": "2024-01-15T10:30:05Z",
      "completed_by": "f30ed1f9-be44-46a3-9050-03e9561e94f0",
      "state": "committed",
      "params": { "skip_refresh": false },
      "plan_summary": { "add": 2, "change": 1, "destroy": 0 },
      "state_names": ["networking"],
      "tags": {"desc": "Backend update"}
    }
  ]
}
```

`state` is one of `open`, `previewing`, `previewed`, `committing`, `committed`, `failed`, `failed-committed`, or `aborted`. `created_by_name`, `plan_summary`, and `state_names` are present when the endpoint loads them.

### Get transaction

```text
GET /api/v1/tx/{tx_id}
```

Returns one transaction, with the IDs of the states that it writes to.

Response:

```json
{
  "tx": { "id": "455fe705-f27f-4335-9355-dbe8f14098df", "state": "committed", "...": "..." },
  "state_ids": ["550e8400-e29b-41d4-a716-446655440000"],
  "share_url": null
}
```

### Create transaction

```text
POST /api/v1/tenants/{tenant_id}/tx/create
```

Creates a transaction.

Request body:

```json
{
  "state_schema_version": 4,
  "params": { "skip_refresh": false },
  "tags": {
    "pipeline": "github-actions",
    "commit": "abc123"
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `state_schema_version` | integer | Yes | State schema version the client writes. [`GET /api/v1/version`](/docs/reference/api/server#get-version) reports the current value of the server |
| `params.skip_refresh` | boolean | No | Skip the refresh step when previewing |
| `tags` | object | No | Metadata tags |

Response: `201 Created` with the transaction object.

### Get transaction logs

```text
GET /api/v1/tx/{tx_id}/logs
```

Returns the logs of a transaction.

Response:

```json
{
  "results": [
    {
      "id": "log-123",
      "action": "state_set",
      "object_type": "instance",
      "created_at": "2024-01-15T10:30:00Z",
      "state_id": "state-123",
      "data": { ... }
    }
  ]
}
```

### Abort transaction

```text
POST /api/v1/tx/{tx_id}/abort
```

Aborts an active transaction.

Response: `200 OK` with the transaction object.

### Plan operations

```text
GET /api/v1/tx/{tx_id}/plan-operations
```

Returns the per-resource plan operations recorded at preview time, ordered by address. Paginated through the `Link` header (`limit` defaults to 200, maximum 1000).

Response:

```json
{
  "results": [
    { "address": "aws_instance.web", "operation": "update" }
  ]
}
```

`operation` is one of `create`, `update`, `replace`, or `destroy`.

### Transaction output

```text
GET /api/v1/tx/{tx_id}/output
```

Returns the captured apply output as stored chunk rows. Reassemble them in `idx` order. Paginated through the `Link` header, one stored fragment per page by default (`limit` maximum 1000).

Response:

```json
{
  "payload": "apply_stdout",
  "results": [
    { "idx": 0, "data": "..." }
  ]
}
```

`payload` is `apply_stdout` or `run_failure`.

### State map

```text
GET /api/v1/tx/{tx_id}/state-map
```

Returns the IDs of the states that the transaction touches, as `{ "results": ["..."] }`.

### Transaction lifecycle endpoints

The CLI drives a transaction through these endpoints during `stategraph tf plan` and `stategraph tf apply`. They are listed for completeness. The CLI is the supported client.

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/tx/session/create` | Create a transaction and return a session `token` scoped to it. Body: `{ "tags": {...} }` |
| `POST` | `/api/v1/tx/{tx_id}/logs/append` | Append transaction log entries (HCL, files, tfvars, and state objects) |
| `POST` | `/api/v1/tx/{tx_id}/preview` | Start the preview (plan). Returns a `task` to poll and a `token` |
| `POST` | `/api/v1/tx/{tx_id}/commit` | Start the commit (apply). Returns a `task` to poll and a `token`; `409` when the transaction conflicts with a committed one |
| `POST` | `/api/v1/tx/{tx_id}/apply` | Apply the transaction's logged content to its states. `?replace=delta` (default), `overwrite`, or `hcl` selects how it relates to what is already committed |
| `POST` | `/api/v1/actuator/bundle` | Fetch a page of the minimal configuration bundle (`{ "limit", "cursor" }`) the CLI runs locally |
| `POST` | `/api/v1/actuator/bundle/cursors` | List the bundle page cursors for a given `limit` |
| `POST` | `/api/v1/actuator/bundle/generate` | Generate the bundle for a task |
| `GET` | `/api/v1/actuator/params` | Parameters for the local run (`skip_refresh`) |
| `POST` | `/api/v1/actuator/preview` | Returns the preview result (`has_changes`, `plan`) |
| `POST` | `/api/v1/actuator/results` | Report a local run result fragment (`idx`, `request`) |

## Tasks

A long-running operation returns a task ID, so that the request does not block. Poll the task until it completes. Examples are bundle generation, cost recompute, security scans, [repository refresh](/docs/reference/api/vcs-installations#refresh-repositories), large imports and exports, and bulk operations across many resources.

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/tasks` | Create a task |
| `GET` | `/api/v1/tasks/{task_id}` | Task status: `{ "id", "state" }` with `state` one of `pending`, `running`, `completed`, `failed`, or `aborted`. `404` when no task has this ID |
| `GET` | `/api/v1/tasks/{task_id}/results` | Number of stored result fragments: `{ "count" }` |
| `GET` | `/api/v1/tasks/{task_id}/result[?idx=N]` | The task's result. `idx` fetches one fragment; omit it for the whole result, reassembled |

```bash
curl -X GET \
  https://app.stategraph.cloud/api/v1/tasks/{task_id} \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

This script polls a task until it completes:

```bash
#!/bin/bash
TASK_ID="task_id_from_async_operation"

while true; do
  STATUS=$(curl -s "https://app.stategraph.cloud/api/v1/tasks/$TASK_ID" \
    -H "Authorization: Bearer $ACCESS_TOKEN")

  echo "Task status: $STATUS"

  # Check if task is complete (adjust based on actual response structure)
  if echo "$STATUS" | grep -q "completed"; then
    echo "Task completed!"
    break
  fi

  sleep 5
done
```

When you poll:

- Poll every 5 to 10 seconds, to stay under the rate limit.
- Back off exponentially for a long-running task.
- Set a maximum wait, so that the loop always ends.
- Handle the error states.
