---
title: Server
description: API endpoints that return the version of the server, its feature flags, its GitHub and GitLab configuration, and the GitHub App client ID.
order: 14
---


These endpoints describe the server: its version, its feature flags, its GitHub and GitLab configuration, and the OAuth client ID of its GitHub App.

## Get version

```text
GET /api/v1/version
```

Returns the server version and the state schema version that it writes.

Response:

```json
{ "version": "2.5.7", "state_schema_version": 4 }
```

## Get server capabilities

```text
GET /api/v1/capabilities
```

Returns the feature flags of the server, so that clients such as the console can decide which features to offer. They are server-wide, unlike the per-user `capabilities` from [`GET /api/v1/whoami`](/docs/reference/api/users#get-current-user).

Response:

```json
{
  "costs": { "enabled": true },
  "security": { "enabled": true },
  "dedicated": { "enabled": false },
  "github_app_url": "https://github.com/apps/example-app/installations/new"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `costs.enabled` | boolean | Whether the server can answer cost queries |
| `security.enabled` | boolean | Whether security scanning is enabled (see `STATEGRAPH_SECURITY`) |
| `dedicated.enabled` | boolean | Whether dedicated-instance endpoints are reachable |
| `github_app_url` | string | URL that starts the GitHub App installation flow. Absent when the server has no `GITHUB_APP_URL` configured |

## Get server configuration

```text
GET /api/v1/server/config
```

Returns the VCS provider configuration of the server (schema `server-config`). Status codes: `200`.

```json
{
  "github": {
    "api_base_url": "https://api.github.com",
    "app_client_id": "string",
    "app_url": "https://github.com/apps/example-app",
    "web_base_url": "https://github.com"
  },
  "gitlab": {
    "api_base_url": "https://gitlab.com",
    "app_id": "string",
    "redirect_url": "https://app.stategraph.cloud/api/v1/gitlab/callback",
    "web_base_url": "https://gitlab.com"
  }
}
```

Each object is present only when the server is configured for that provider.

| Field | Description |
|-------|-------------|
| `github.api_base_url` | The GitHub API the server calls |
| `github.app_client_id` | The OAuth client ID of the GitHub App |
| `github.app_url` | The public page of the GitHub App |
| `github.web_base_url` | The GitHub web address |
| `gitlab.api_base_url` | The GitLab API the server calls |
| `gitlab.app_id` | The ID of the GitLab OAuth application |
| `gitlab.redirect_url` | The OAuth callback URL to register on the GitLab application |
| `gitlab.web_base_url` | The GitLab web address |

```bash
curl -X GET \
  https://app.stategraph.cloud/api/v1/server/config
```

Use it to:

- Find which VCS providers the server is configured for: GitHub, GitLab, or both.
- Read the GitHub and GitLab addresses that a client application calls.
- Verify the configuration of a self-hosted server.

## Get GitHub client ID

```text
GET /api/v1/github/client_id
```

Returns the OAuth client ID of the GitHub App. The GitLab OAuth application ID is `gitlab.app_id` in the server configuration. Status codes: `200`, `403`.

This endpoint needs no authentication, so OAuth flows can get the client ID during the initial OAuth setup.

```json
{
  "client_id": "string"
}
```

```bash
curl -X GET \
  https://app.stategraph.cloud/api/v1/github/client_id
```

Use it to:

- Implement custom OAuth flows.
- Build third-party integrations.
- Configure authentication in client applications.
- Verify the GitHub App configuration.
