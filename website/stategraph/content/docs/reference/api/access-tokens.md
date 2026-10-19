---
title: API keys and access tokens
description: API endpoints for API keys, default capabilities, and capability group rules, and for refresh tokens and the short-lived access tokens they issue.
order: 5
---


These endpoints manage the credentials of the API and what each credential can do: API keys, default capabilities, capability group rules, and refresh tokens with their short-lived access tokens. For how to send each credential, see [Authentication](/docs/reference/api#authentication).

## API keys

An API key authenticates the CLI, Terraform, and API requests as a bearer token. The CLI calls API keys access tokens (`stategraph user access-tokens`).

### Create API key

```text
POST /api/v1/user/access-tokens
```

Request body: the required `name` labels the key. The optional `capabilities` object limits what the key can do, with the same model as `whoami`:

```json
{
  "name": "ci-prod-apply",
  "capabilities": {
    "commit": {
      "states": { "a1b2c3d4-5678-90ab-cdef-1234567890ab": ["*"] }
    }
  }
}
```

Without `capabilities`, the key inherits all the session capabilities of its creator. Stategraph masks the requested capabilities with those of the creator, so a key never exceeds the identity that created it. See [Access tokens and capabilities](/docs/admin/access-control/access-tokens) for the CLI equivalent and the full capability model.

Response: `201 Created`. The response shows the key only one time. Store it securely.

```json
{ "token": "eyJhbGciOiJIUzI1NiIs..." }
```

### List API keys

```text
GET /api/v1/user/access-tokens
```

Response:

```json
{
  "tokens": [
    {
      "id": "...",
      "name": "my-api-key",
      "created_at": "2026-06-04T10:30:00Z",
      "owner_id": "...",
      "owner_name": "jane@example.com",
      "owner_type": "user"
    }
  ]
}
```

Each token object always includes `id`, `name`, `created_at`, `owner_id`, `owner_name`, and `owner_type`. `expiration` is present only when the token has an expiry.

### Revoke API key

```text
POST /api/v1/user/access-tokens/revoke?token_id={id}
```

Revokes the key with the given ID.

Response:

```json
{
  "id": "f02791c8-aa63-4cdf-acae-a7c968d8a831",
  "revoked": true
}
```

## Capabilities

These endpoints manage the default capabilities that each session starts with, and the tenant group rules that grant more at login. The `capabilities` object has the same shape as in `whoami`. See [Access tokens and capabilities](/docs/admin/access-control/access-tokens) for the CLI (`stategraph caps`).

### Default capabilities

```text
GET /api/v1/caps/default
PUT /api/v1/caps/default
```

Reads or replaces the default capabilities of the installation. Admin only (`403` otherwise).

Request and response:

```json
{
  "capabilities": { "preview": {} }
}
```

### List group rules

```text
GET /api/v1/tenants/{tenant_id}/caps/group-rules
```

Lists the active capability group rules of the tenant. Requires admin of the tenant (an installation-wide admin qualifies). Each rule maps an identity-provider group `condition` to a capability `grant`. At login, the grant is added (a union) to the capabilities of each matching user.

Response:

```json
{
  "rules": [
    {
      "id": "...",
      "condition": { "group": "eng-*" },
      "grant": { "commit": { "tenants": ["550e8400-e29b-41d4-a716-446655440000"] } },
      "description": "Engineers may apply",
      "created_at": "2026-06-04T10:30:00Z",
      "created_by": "f30ed1f9-be44-46a3-9050-03e9561e94f0"
    }
  ]
}
```

### Create group rule

```text
POST /api/v1/tenants/{tenant_id}/caps/group-rules
```

Creates a rule that the tenant owns. The `grant` must be scoped to this tenant and no wider. The server rejects installation-level capabilities (unscoped `admin`, `sudo`, access-token create and refresh) and grants that name the states of another tenant: `400` when the grant is malformed, `422` when it reaches beyond this tenant.

Request body:

```json
{
  "condition": { "group": "eng-*" },
  "grant": { "commit": { "tenants": ["550e8400-e29b-41d4-a716-446655440000"] } },
  "description": "Engineers may apply"
}
```

Response: `200 OK` with `{ "id": "..." }`.

### Delete group rule

```text
DELETE /api/v1/tenants/{tenant_id}/caps/group-rules/{id}
```

Soft-deletes one of the rules of the tenant, and keeps the row for audit. The answer is `404` when this tenant has no such active rule.

Response: `200 OK`

## Refresh tokens and access tokens

!!! note "Enterprise"
    The `/api/v1/{vcs}/access-token` endpoints are part of the Enterprise edition. They are available on [Stategraph Cloud](https://app.stategraph.cloud) and on self-hosted Enterprise deployments. The Open Source edition does not have them. See [Editions](/docs/get-started/editions).

A refresh token is long-lived. It keeps the capabilities that you select when you create it, and it can only get access tokens. An access token is short-lived: it has the capabilities of its refresh token, and it expires after 60 seconds. For the full flow, see [Access tokens](/docs/reference/api#access-tokens).

Which token to send:

- For `POST /api/v1/access-token/refresh`: the refresh token. This is the only endpoint that takes it.
- For the `/api/v1/{vcs}/access-token` endpoints: an access token from the refresh endpoint.

```text
Authorization: Bearer YOUR_TOKEN
```

`{vcs}` is `github` or `gitlab`. The examples use `github`. For a GitLab installation, use `gitlab` in the path, for example `/api/v1/gitlab/access-token`.

### Create refresh token

```text
POST /api/v1/{vcs}/access-token
```

Creates a refresh token. Status codes: `200`, `400`, `403`.

Request body (schema `access-token-create`):

```json
{
  "name": "string",
  "capabilities": [
    "kv_store_read",
    "kv_store_write",
    {
      "name": "installation_id",
      "id": "12345"
    }
  ]
}
```

See [Refresh token capabilities](#refresh-token-capabilities) for all options.

Response (schema `access-token`):

```json
{
  "refresh_token": "string"
}
```

```bash
curl -X POST \
  https://app.stategraph.cloud/api/v1/github/access-token \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "CI/CD Token",
    "capabilities": ["kv_store_read", "kv_store_write"]
  }'
```

### List refresh tokens

```text
GET /api/v1/{vcs}/access-token
```

Returns a page of refresh tokens. Status codes: `200`, `403`.

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `limit` | integer | No | Maximum number of results |
| `page` | array[string] | No | Pagination token |

Response (schema `access-token-page`):

```json
{
  "results": [
    {
      "id": "string",
      "name": "string",
      "capabilities": [
        "kv_store_read",
        "kv_store_write",
        {
          "name": "installation_id",
          "id": "12345"
        }
      ]
    }
  ]
}
```

```bash
curl -X GET \
  "https://app.stategraph.cloud/api/v1/github/access-token?limit=50" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Delete refresh token

```text
DELETE /api/v1/{vcs}/access-token
```

Deletes a refresh token by ID. Status codes: `200`, `403`, `404`.

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `id` | string | Yes | The ID of the token to delete |

```bash
curl -X DELETE \
  "https://app.stategraph.cloud/api/v1/github/access-token?id=TOKEN_ID" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Refresh access token

```text
POST /api/v1/access-token/refresh
```

Exchanges a refresh token for an access token with the capabilities that you selected for the refresh token. Send the refresh token as the bearer token: `YOUR_API_KEY` in the example. Status codes: `200`, `403`.

Response schema:

```json
{
  "token": "string"
}
```

Example request:

```bash
curl -X POST \
  https://app.stategraph.cloud/api/v1/access-token/refresh \
  -H "Authorization: Bearer YOUR_API_KEY"
```

Response:

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Refresh token capabilities

When you create a refresh token, you give it one or more capabilities. A capability is a string, or an object with more properties.

| Capability | Description |
|------------|-------------|
| `access_token_refresh` | Refresh access tokens to get new short-lived tokens |
| `access_token_create` | Create refresh tokens |
| `kv_store_read` | Read the key-value store |
| `kv_store_write` | Write to the key-value store |
| `kv_store_system_read` | Read the system key-value store |
| `kv_store_system_write` | Write to the system key-value store |

```json
{
  "name": "My Token",
  "capabilities": ["kv_store_read", "kv_store_write"]
}
```

Two object capabilities scope the token:

| Object | Properties | Scopes the token to |
|--------|------------|---------------------|
| Installation ID | `name`: `"installation_id"`. `id`: the installation ID string. | One installation |
| VCS provider | `name`: `"vcs"`. `vcs`: `"github"` or `"gitlab"`. | One VCS provider |

```json
{
  "name": "installation_id",
  "id": "12345"
}
```

```json
{
  "name": "vcs",
  "vcs": "github"
}
```

You can mix string and object capabilities:

```json
{
  "name": "Production Token",
  "capabilities": [
    "kv_store_read",
    "kv_store_write",
    {
      "name": "installation_id",
      "id": "67890"
    },
    {
      "name": "vcs",
      "vcs": "github"
    }
  ]
}
```
