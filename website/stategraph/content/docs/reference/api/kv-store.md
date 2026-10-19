---
title: Key-value store
description: API endpoints for the key-value store of an installation: set, get, delete, compare-and-swap, iterate, count, measure, and commit keys.
order: 13
---


The key-value store keeps data for each installation across workflow runs. These endpoints set, get, delete, iterate, count, measure, and commit keys. Use the store to:

- Share state between workflow runs.
- Store metadata and configuration.
- Implement counters and locks.
- Cache the results of expensive computations.
- Coordinate across more than one pull request.

In production workflows, use the `committed` parameter to read stable, committed data.

## Path parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `vcs` | string | Yes | VCS provider: `github` or `gitlab` |
| `installation_id` | string | Yes | The installation identifier. For a GitLab installation, the GitLab group ID |
| `key` | string | Yes | The key name. For iterate, count, and size, the key or a key prefix |

The examples use `github`.

## Set value

```text
PUT /api/v1/{vcs}/kv/{installation_id}/key/{key}
```

Stores or updates a key-value pair. Status codes: `200`, `403`.

Request body (schema `kv-set`):

```json
{
  "data": "string",
  "idx": 0,
  "committed": false,
  "read_caps": [],
  "write_caps": []
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `data` | string | Yes | The value to store (JSON stringified if needed) |
| `idx` | integer | No | Index for versioning (default: 0) |
| `committed` | boolean | No | Whether to commit the value immediately |
| `read_caps` | array | No | Read capability restrictions for this key |
| `write_caps` | array | No | Write capability restrictions for this key |

Response (schema `kv-record`):

```json
{
  "key": "string",
  "data": "string",
  "idx": 0,
  "version": 1,
  "committed": true,
  "created_at": "2025-01-15T10:30:00Z",
  "size": 1024,
  "read_caps": [],
  "write_caps": []
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `key` | string | Yes | The key name |
| `data` | string | Yes | The stored value |
| `idx` | integer | Yes | Index version |
| `version` | integer | Yes | Record version for optimistic locking |
| `committed` | boolean | Yes | Whether the record is committed |
| `created_at` | string | Yes | ISO 8601 timestamp of when the record was created |
| `size` | integer | Yes | Size of the stored data in bytes |
| `read_caps` | array | No | Read capability restrictions for this key |
| `write_caps` | array | No | Write capability restrictions for this key |

```bash
curl -X PUT \
  https://app.stategraph.cloud/api/v1/github/kv/{installation_id}/key/my-key \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"data": "my-value", "idx": 0}'
```

## Get value

```text
GET /api/v1/{vcs}/kv/{installation_id}/key/{key}
```

Returns the record of a key (schema `kv-record`). Status codes: `200`, `403`, `404`.

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `committed` | boolean | No | Only return committed values |
| `idx` | integer | No | Specific index to retrieve |
| `select` | array[string] | No | Fields to select from the record |

```bash
curl -X GET \
  "https://app.stategraph.cloud/api/v1/github/kv/{installation_id}/key/my-key?committed=true" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## Delete value

```text
DELETE /api/v1/{vcs}/kv/{installation_id}/key/{key}
```

Deletes a key-value pair. Status codes: `200`, `403`.

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `idx` | integer | No | Specific index to delete |
| `version` | integer | No | Version number for optimistic locking |

Response (schema `kv-delete`). `result` (boolean) is whether the key was deleted:

```json
{
  "result": true
}
```

## Compare-and-swap (CAS)

```text
PUT /api/v1/{vcs}/kv/{installation_id}/cas/key/{key}
```

Updates a value atomically, only when its current version matches the expected version. Status codes: `200` with the updated record (schema `kv-record`), `400` when the CAS condition fails (version mismatch), and `403`.

Request body (schema `kv-cas`):

```json
{
  "data": "string",
  "idx": 0,
  "version": 1,
  "committed": false,
  "read_caps": [],
  "write_caps": []
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `data` | string | Yes | The new value to store |
| `idx` | integer | No | Index for versioning |
| `version` | integer | Yes | Expected current version (the CAS fails if the version does not match) |
| `committed` | boolean | No | Whether to commit the value immediately |
| `read_caps` | array | No | Read capability restrictions for this key |
| `write_caps` | array | No | Write capability restrictions for this key |

```bash
curl -X PUT \
  https://app.stategraph.cloud/api/v1/github/kv/{installation_id}/cas/key/my-key \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"data": "new-value", "version": 1}'
```

## Iterate keys

```text
GET /api/v1/{vcs}/kv/{installation_id}/iter/{key}
```

Returns the records of the keys that match a pattern or prefix. Status codes: `200`, `403`.

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `committed` | boolean | No | Only return committed values |
| `idx` | integer | No | Starting index for iteration |
| `limit` | integer | No | Maximum number of records to return |
| `include_data` | boolean | No | Include record data in the response |
| `inclusive` | boolean | No | Include the starting key in the results |
| `prefix` | boolean | No | Treat the key as a prefix for matching |
| `select` | array[string] | No | Fields to select from the records |

Response (schema `kv-record-list`). `records` is an array of `kv-record` objects, as in [Set value](#set-value):

```json
{
  "records": [
    {
      "key": "string",
      "data": "string",
      "idx": 0,
      "version": 1,
      "committed": true
    }
  ]
}
```

```bash
curl -X GET \
  "https://app.stategraph.cloud/api/v1/github/kv/{installation_id}/iter/my-prefix?prefix=true&limit=100" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## Count keys

```text
GET /api/v1/{vcs}/kv/{installation_id}/count/key/{key}
```

Counts the keys that match a pattern or prefix. Status codes: `200`, `403`.

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `committed` | boolean | No | Only count committed values |

Response (schema `kv-count`):

```json
{
  "count": 42,
  "max_idx": 5
}
```

| Field | Type | Description |
|-------|------|-------------|
| `count` | integer | Number of keys matching the query |
| `max_idx` | integer | Maximum index value among the counted keys |

## Get size

```text
GET /api/v1/{vcs}/kv/{installation_id}/size/key/{key}
```

Returns the storage size of a key or key prefix. Status codes: `200`, `403`, `404`.

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `committed` | boolean | No | Only measure committed values |
| `idx` | integer | No | Specific index to measure |

Response (schema `kv-size`). `size` (integer) is the size of the stored data in bytes:

```json
{
  "size": 1024
}
```

## Commit keys

```text
POST /api/v1/{vcs}/kv/{installation_id}/commit
```

Commits a batch of key-value operations atomically. Status codes: `200`, `403`.

Request body (schema `kv-commit`):

```json
{
  "keys": [
    {
      "key": "string",
      "idx": 0
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `keys` | array | Yes | Array of key objects to commit |
| `keys[].key` | string | Yes | The key name to commit |
| `keys[].idx` | integer | No | Optional index for the key |

Response (schema `kv-commit-result`). `keys` holds the committed keys, each with its `key` and `idx`:

```json
{
  "keys": [
    {
      "key": "string",
      "idx": 0
    }
  ]
}
```

```bash
curl -X POST \
  https://app.stategraph.cloud/api/v1/github/kv/{installation_id}/commit \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"keys": [{"key": "my-key", "idx": 0}]}'
```
