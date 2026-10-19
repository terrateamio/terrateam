---
title: Stategraph API
description: The Stategraph REST API: base URL, API keys, sessions, and access tokens, the OpenAPI schema, pagination, errors, and rate limits.
order: 1
---


The Stategraph REST API gives programmatic access to users and tenants, states, queries, transactions, costs, security findings, VCS installations, and the key-value store. Use it to add Stategraph to your CI/CD pipelines, custom workflows, and automation. The `stategraph` CLI and the console use it too.

!!! note "Beta"
    These endpoints are in beta and can change: the GitHub and GitLab user and [installation](/docs/reference/api/vcs-installations#installations) endpoints, stacks, the key-value store, refresh tokens, the server configuration, and the GitHub client ID. Version your integrations and watch for updates.

## Base URL

- Stategraph Cloud: `https://app.stategraph.cloud`
- A self-hosted server: its public base URL, the value of `STATEGRAPH_UI_BASE`
- A local Docker Compose stack: `http://localhost:8080`

Each path starts with `/api`. For example, `GET /api/v1/whoami` on Stategraph Cloud is `https://app.stategraph.cloud/api/v1/whoami`. In a path, `{vcs}` is `github` for GitHub or `gitlab` for GitLab. Request bodies are JSON (`Content-Type: application/json`).

Some examples use `$STATEGRAPH_API_BASE` for the server address and `$STATEGRAPH_API_KEY` for the API key, as the CLI does. The others use the Stategraph Cloud address.

## Authentication

Send a credential in the `Authorization` header as a bearer token: an API key, a session token, or an access token. A browser sends a session cookie instead.

### API keys

An API key authenticates the `stategraph` CLI, Terraform, and API requests. Create one in the console under **Settings > API Keys**, or with [`POST /api/v1/user/access-tokens`](/docs/reference/api/access-tokens#create-api-key).

```bash
curl -H "Authorization: Bearer $STATEGRAPH_API_KEY" "$STATEGRAPH_API_BASE/api/v1/whoami"
```

### Session cookie

Sign-in sets a session cookie, and the browser sends it automatically. [Login with password](/docs/reference/api/users#login-with-password) also returns the session as a token for bearer authentication. There are three sign-in modes:

- [Local authentication](/docs/admin/access-control/local-authentication): email and password, with user management. This is the default.
- [Google OAuth](/docs/admin/access-control/google-oauth): single sign-on through Google Workspace.
- [Generic OIDC](/docs/admin/access-control/oidc): any OIDC-compatible provider.

### Access tokens

The GitHub and GitLab user and [installation](/docs/reference/api/vcs-installations#installations) endpoints, stacks, the key-value store, the server configuration, and the refresh token endpoints take a short-lived access token. You get it in two steps:

1. Create a refresh token with a name and the capabilities that it needs, with [`POST /api/v1/{vcs}/access-token`](/docs/reference/api/access-tokens#create-refresh-token). The response shows it one time. A refresh token is long-lived, and it can only get access tokens.
2. Send the refresh token as the bearer token to `POST /api/v1/access-token/refresh`. In the examples, `YOUR_API_KEY` and `your_api_key` stand for the refresh token.

```bash
curl -X POST https://app.stategraph.cloud/api/v1/access-token/refresh \
  -H "Authorization: Bearer YOUR_API_KEY"
```

The response holds the access token. The access token has the capabilities that you selected for the refresh token.

```json
{
  "token": "eyJhbGc..."
}
```

Send the access token on each request:

```text
Authorization: Bearer YOUR_ACCESS_TOKEN
```

```bash
curl -X GET https://app.stategraph.cloud/api/v1/whoami \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

An access token expires after 60 seconds. This limits the damage when someone intercepts a token. To continue, call the refresh endpoint again for a new token. This script gets its first token, then a new one every 50 seconds, before the 60-second expiry:

```bash
#!/bin/bash
API_KEY="your_api_key_here"

get_access_token() {
  curl -s -X POST https://app.stategraph.cloud/api/v1/access-token/refresh \
    -H "Authorization: Bearer $API_KEY" | jq -r '.token'
}

ACCESS_TOKEN=$(get_access_token)

while true; do
  # Use the token
  curl -X GET https://app.stategraph.cloud/api/v1/whoami \
    -H "Authorization: Bearer $ACCESS_TOKEN"

  # Wait and refresh
  sleep 50
  ACCESS_TOKEN=$(get_access_token)
done
```

This Python client refreshes the token when it is 55 seconds old:

```python
from datetime import datetime, timedelta

from requests import get, post

class StategraphClient:
    def __init__(self, api_key):
        self.api_key = api_key
        self.access_token = None
        self.token_expires_at = None
        self.base_url = "https://app.stategraph.cloud"

    def refresh_token(self):
        """Get a new access token"""
        response = post(
            f"{self.base_url}/api/v1/access-token/refresh",
            headers={"Authorization": f"Bearer {self.api_key}"}
        )
        self.access_token = response.json()["token"]
        # Set expiration to 55 seconds (5 second buffer)
        self.token_expires_at = datetime.now() + timedelta(seconds=55)

    def get_headers(self):
        """Get headers with valid access token"""
        if not self.access_token or datetime.now() >= self.token_expires_at:
            self.refresh_token()
        return {"Authorization": f"Bearer {self.access_token}"}

    def whoami(self):
        """Example API call"""
        response = get(
            f"{self.base_url}/api/v1/whoami",
            headers=self.get_headers()
        )
        return response.json()

client = StategraphClient("your_api_key")
user = client.whoami()
```

### Keep credentials safe

- Keep API keys and refresh tokens in environment variables or a secrets manager. Never commit them to version control.
- Give each key only the capabilities that it needs.
- Replace keys regularly: create new ones and delete the old ones.
- Delete the keys that you do not use.

## OpenAPI schema

```text
GET /api/v1/openapi
```

Returns the OpenAPI schema of the API as JSON. It needs no authentication. Use it to discover endpoints and request and response types, and with tools that read OpenAPI specifications. The schema does not include the paths that start with `/api/github`, `/api/v1/github`, `/api/v1/gitlab`, `/api/v1/user/github`, `/api/v1/access-token`, or `/api/v1/server`.

```bash
curl "$STATEGRAPH_API_BASE/api/v1/openapi"
```

Response: `200 OK` with the complete OpenAPI JSON schema. Each [release](/docs/reference/releases) also has the schema as a downloadable file.

## Pagination

Many list endpoints use cursor-based pagination: `limit` sets the page size, and `page` takes the cursor. Request the first page:

```bash
curl "$STATEGRAPH_API_BASE/api/v1/tenants/$TENANT_ID/states?limit=50" \
  -H "Authorization: Bearer $STATEGRAPH_API_KEY"
```

Request the next page with the cursor from the previous response:

```bash
curl "$STATEGRAPH_API_BASE/api/v1/tenants/$TENANT_ID/states?limit=50&page=cursor..." \
  -H "Authorization: Bearer $STATEGRAPH_API_KEY"
```

```text
GET /api/v1/github/installations/{installation_id}/repos?limit=50&page=...
GET /api/v1/gitlab/installations/{installation_id}/repos?limit=50&page=...
```

Some list endpoints take the cursor in `cursor`, from the `next_cursor` of the previous response. Others return the next page in a `Link` header. Each endpoint lists its parameters.

## Filtering and sorting

Some list endpoints take a filter in `q` and a sort direction in `d` (`asc` or `desc`):

```text
GET /api/v1/github/installations/{installation_id}/work-manifests?q=terraform&d=desc
GET /api/v1/gitlab/installations/{installation_id}/work-manifests?q=terraform&d=desc
```

The value of `q` depends on the endpoint: `key:value` filter terms for instances, and a search query for dirspaces and work manifests.

## Errors

The API uses standard HTTP status codes:

| Code | Meaning |
|------|---------|
| `200` | The request succeeded. |
| `400` | Bad request: invalid parameters. |
| `401` | Authentication is required. The response has no body. |
| `403` | Forbidden: the credential is missing or invalid, or it does not allow the request. |
| `404` | The resource does not exist. |
| `429` | Too many requests. See [Rate limiting](#rate-limiting). |
| `500` | A server error occurred. |

The body of a `400` depends on the endpoint. Many endpoints return a structured error:

```json
{
  "id": "INVALID_DATE_PARAM",
  "data": "Error description"
}
```

`id` is a machine-readable error code, for example `INVALID_DATE_PARAM` or `INVALID_GROUP_BY`. Some validation failures, such as a malformed UUID when you create a state, return a `400` with an empty body. Check the status code first, and do not expect a JSON body on every `400`.

## Rate limiting

The API limits the request rate, to prevent abuse and keep usage fair. A request over the limit gets `429 Too Many Requests`. Retry it with exponential backoff.

## Endpoint pages

| Page | Endpoints |
|------|-----------|
| [Users and sign-in](/docs/reference/api/users) | The current user, their tenants, and their GitHub and GitLab users, login, logout, and first-time setup |
| [User management](/docs/reference/api/user-management) | Users, passwords, installation admins, and service accounts |
| [Tenants and members](/docs/reference/api/tenants) | Tenants, members and their roles, and invitations |
| [API keys and access tokens](/docs/reference/api/access-tokens) | API keys, default capabilities, group rules, refresh tokens, and access tokens |
| [States](/docs/reference/api/states) | States, the Terraform HTTP backend, instances, blast radius, modules, and summaries |
| [Transactions and tasks](/docs/reference/api/transactions) | Transactions, their logs, plan operations, and output, and long-running tasks |
| [Queries and gap analysis](/docs/reference/api/queries) | SQL queries, the SQL schema, and the cloud resources that no state manages |
| [Cost and billing](/docs/reference/api/cost) | Cost snapshots, history, attribution, plan-time cost, and billing sources |
| [Security](/docs/reference/api/security) | Security findings, scans, and the security impact of a transaction |
| [VCS installations](/docs/reference/api/vcs-installations) | GitHub and GitLab installations: tenant links, repositories, pull requests, dirspaces, work manifests, groups, and webhooks |
| [Stacks](/docs/reference/api/stacks) | The stacks of a pull request |
| [Key-value store](/docs/reference/api/kv-store) | Data that persists across workflow runs |
| [Server](/docs/reference/api/server) | The version, feature flags, and VCS configuration of the server, and the GitHub client ID |

## Next steps

- [Access tokens and capabilities](/docs/admin/access-control/access-tokens): the capability model behind API keys.
- [CLI reference](/docs/cli): the command-line client for this API.
- [Pull request commands](/docs/reference/orchestration/commands/help): drive Orchestration from the pull request instead.
