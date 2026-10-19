---
title: Queries and gap analysis
description: API endpoints that run SQL queries across all states, return the SQL schema, and find and import the cloud resources that no state manages.
order: 8
---


These endpoints run SQL queries across all states and return the SQL schema. They also find the cloud resources that no state manages, and generate import blocks for them.

## SQL queries

### Execute SQL query

```text
GET /api/v1/mql
```

Runs an SQL query across all states.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `q` | query | Yes | SQL query string |
| `page` | query | No | Pagination cursor |
| `tz` | query | No | Timezone for date formatting |

```bash
curl "$STATEGRAPH_API_BASE/api/v1/mql?q=SELECT%20*%20FROM%20resources%20WHERE%20type%20%3D%20%27aws_instance%27" \
  -H "Authorization: Bearer $STATEGRAPH_API_KEY"
```

Response:

```json
[
  {
    "address": "aws_instance.web",
    "type": "aws_instance",
    ...
  }
]
```

Result size:

- The `LIMIT` clause of the query sets the number of rows, up to 1000. The endpoint ignores a `limit` query parameter: put the bound in `LIMIT`.
- A query without `LIMIT` returns at most 20 rows. When this default truncates the result, the response has an `mql-default-limit-applied` header, so that clients can detect the truncation and not undercount.
- To get more rows, add an explicit `LIMIT`, or paginate with `ORDER BY`.

[Get SQL schema](#get-sql-schema) reports the active `default_limit` and `max_limit`.

Cursor pagination:

Cursor pagination uses an RFC 5988 `Link` response header. It needs an `ORDER BY` clause, because deterministic paging requires a stable sort order.

- With `ORDER BY`: when more rows remain, the response has a `Link` header with `rel="next"` (and `rel="prev"` when you page through results). Follow the `Link` URL for the next page.

```text
Link: <https://app.stategraph.cloud/api/v1/mql?page=...&q=...>; rel="next"
```

- Without `ORDER BY`: there is no `Link` header. The `mql-pagination-error: ORDER_BY_MISSING` header tells you that the result cannot be paginated. Add `ORDER BY` to page.

### Get SQL schema

```text
GET /api/v1/mql/schema
```

Returns the SQL schema for autocomplete. With the `tables` object, it reports `default_limit` (the row limit for a query without its own `LIMIT`) and `max_limit` (the cap on an explicit `LIMIT`).

## Gap analysis

### Get gap analysis config

```text
GET /api/v1/tenants/{tenant_id}/gaps/config
```

Returns the status of the gap analysis configuration.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `provider` | query | Yes | Cloud provider (for example `aws`) |

Response:

```json
{
  "provider": "aws",
  "status": "ready",
  "ready_for_gap_analysis": true,
  "ready_for_terraform_import": true,
  "has_aggregator": true,
  "aggregator_region": "us-east-1",
  "indexed_regions": ["us-east-1", "us-west-2"],
  "index_count": 2,
  "warnings": []
}
```

### Run gap analysis

```text
GET /api/v1/tenants/{tenant_id}/gaps
```

Returns unmanaged resources. Gap analysis runs asynchronously:

1. The first request for a provider starts a background scan and returns `{ "status": "running", "started_at": <ts> }`.
2. When the scan completes, repeat the request to get the result.
3. Later calls get the result from the cache.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `provider` | query | Yes | Cloud provider |
| `source` | query | No | `cache` (default) or `no-cache` |

Response:

```json
{
  "summary": {
    "total_aws_resources": 1500,
    "managed_by_stategraph": 1200,
    "unmanaged": 300,
    "phantom_filtered": 8
  },
  "unmanaged_resources": [ ... ],
  "fetched_at": 1705312800
}
```

### Generate import

```text
POST /api/v1/tenants/{tenant_id}/gaps/import
```

Generates Terraform import blocks.

Request body:

```json
{
  "provider": "aws",
  "resources": [
    {
      "arn": "arn:aws:s3:::bucket-name",
      "service": "s3",
      "resource_type": "s3:bucket",
      "region": "us-east-1",
      "owning_account_id": "123456789012"
    }
  ]
}
```

Response:

```json
{
  "import_blocks": "import { ... }",
  "provider_hcl": "provider \"aws\" { ... }",
  "generated_hcl": "resource \"aws_s3_bucket\" { ... }",
  "supported_count": 1,
  "unsupported_count": 0,
  "unsupported_resources": []
}
```
