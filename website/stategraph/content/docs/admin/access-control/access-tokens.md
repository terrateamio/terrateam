---
title: Access Tokens and Capabilities
description: Create Stategraph access tokens from the CLI, and limit each token to the admin, plan, apply, and user rights that it needs.
order: 6
---


Capabilities limit what each access token, and each new user, can do in Stategraph. An access token authenticates the CLI, Terraform, and API requests as a Bearer token. Capabilities are the recommended way to issue least-privilege tokens: for example, a token that can apply changes to one state only, and cannot manage users or create tokens.

The `stategraph user access-tokens` commands create, list, and revoke tokens with an existing API key, without a browser session.

## Capability model

A token's capabilities are a subset of those of the session that creates it: a token never exceeds its creator. Without capability flags, or without `capabilities` in the API request, the token inherits all capabilities of that session.

| Capability | Grants | Scope |
|------------|--------|-------|
| `admin` | Full access, over the whole installation when it names no tenants (`{}`), or over the tenants that it names (`{"tenants": [...]}`). See [Tenants and Administration](/docs/admin/access-control/tenants). | Installation-wide or per-tenant |
| `plan` | Plan changes through transactions. | Per-tenant, per-state, and per-subgraph |
| `apply` | Apply changes through transactions. | Per-tenant, per-state, and per-subgraph |
| `users-manage` | Create, update, and delete users. Reset the passwords of users with less authority. Never grants `admin`. See [Who can act on whom](/docs/admin/access-control/tenants). | Installation-wide or per-tenant |
| `sudo` | Act on behalf of specific users. | Per-user |
| `access-token-create` | Issue new access tokens. | Global |
| `access-token-refresh` | Refresh existing access tokens. | Global |

The CLI flags and table output use `plan` and `apply`. In the raw capabilities JSON, which `--capabilities-json` accepts and `stategraph user whoami --format json` returns, they are `preview` and `commit`.

## stategraph user access-tokens create

Create an access token for the current user.

```bash
stategraph user access-tokens create --name <name> [capability flags]
```

`--name` is required. The capability flags select and scope what the token can do.

| Flag | Description |
|------|-------------|
| `--admin` | Grant admin, over the whole installation unless you give `--admin-tenant`. |
| `--admin-tenant <TENANT>` | Restrict admin to these tenants (repeatable). |
| `--plan` | Grant plan. Unrestricted unless scoped with `--plan-tenant`, `--plan-modified`, or `--plan-pulled-in`. |
| `--plan-tenant <TENANT>` | Restrict plan to these tenants (repeatable). |
| `--plan-modified <STATE_ID=PATTERN>` | Restrict plan to the directly modified resources in a state that match PATTERN (repeatable). |
| `--plan-pulled-in <STATE_ID=PATTERN>` | Restrict what plan can pull in: the resources pulled in as cone or blast dependencies in that state must match PATTERN (repeatable). |
| `--apply` | Grant apply. Unrestricted unless scoped with `--apply-tenant`, `--apply-modified`, or `--apply-pulled-in`. |
| `--apply-tenant <TENANT>` | Restrict apply to these tenants (repeatable). |
| `--apply-modified <STATE_ID=PATTERN>` | Restrict apply to the directly modified resources in a state that match PATTERN (repeatable). |
| `--apply-pulled-in <STATE_ID=PATTERN>` | Restrict what apply can pull in: the resources pulled in as cone or blast dependencies in that state must match PATTERN (repeatable). |
| `--users-manage` | Grant users-manage. Unrestricted unless scoped with `--users-manage-tenant`. |
| `--users-manage-tenant <TENANT>` | Restrict users-manage to these tenants (repeatable). |
| `--sudo-user <USER>` | Grant sudo over these users (repeatable). |
| `--access-token-create` | Grant `access-token-create`. |
| `--access-token-refresh` | Grant `access-token-refresh`. |
| `--capabilities-json <json>` | Raw capabilities JSON object. Mutually exclusive with the flags above. |

Tenant and user values are rules:

- A value is a tenant id (or a user), or a prefix that ends in `*`. `*` alone matches everything.
- The most specific matching value decides. A leading `!` refuses.
- When every value refuses, everything else is reached: `--admin-tenant '!t1'` grants admin over every tenant except `t1`, not admin over nothing.

State patterns have the form `STATE_ID=PATTERN`:

- `*` matches the whole state (`sid=*`), a prefix matches part of it (`sid=module.foo.*`), and a leading `!` denies (`--apply-pulled-in 'sid=!module.foo.output.*'`).
- Repeated flags add their patterns together.
- A `STATE_ID` of `*` stands for the states that no other flag of the same name names. So `--apply-modified '*=*' --apply-modified 'sid=!*'` reaches every state except `sid`.
- Without `--*-pulled-in`, a change can pull in anything in the tenants that the capability reaches. So a token that can modify one module, but must not pull in anything outside it, needs both `--*-modified` and `--*-pulled-in`.

### Least-privilege example

A token that can only apply changes to one state:

```bash
stategraph user access-tokens create \
  --name ci-prod-apply \
  --apply \
  --apply-modified 'a1b2c3d4-5678-90ab-cdef-1234567890ab=*'
```

The token value is shown only once. Store it securely.

Output:

```text
field  value
-----  ------------------------------------
token  eyJhbGciOiJIUzI1NiIs...
```

For scripting, use `--format json`:

```json
{ "token": "eyJhbGciOiJIUzI1NiIs..." }
```

## stategraph user access-tokens list

List the access tokens of the current user.

```bash
stategraph user access-tokens list
```

`expiration` is blank for tokens that never expire.

Output:

```text
id                                    name           created_at            expiration  owner_name        owner_type
------------------------------------  -------------  --------------------  ----------  ----------------  ----------
f02791c8-aa63-4cdf-acae-a7c968d8a831  ci-prod-apply  2026-06-04T10:30:00Z              jane@example.com  user
```

`--format json` also includes `owner_id`:

```json
{
  "tokens": [
    {
      "id": "f02791c8-aa63-4cdf-acae-a7c968d8a831",
      "name": "ci-prod-apply",
      "created_at": "2026-06-04T10:30:00Z",
      "owner_id": "550e8400-e29b-41d4-a716-446655440000",
      "owner_name": "jane@example.com",
      "owner_type": "user"
    }
  ]
}
```

## stategraph user access-tokens delete

Revoke an access token by id. `--token-id` is required.

```bash
stategraph user access-tokens delete --token-id <uuid>
```

Output:

```text
field    value
-------  ------------------------------------
id       f02791c8-aa63-4cdf-acae-a7c968d8a831
revoked  true
```

## Inspecting your capabilities

[`stategraph user whoami`](/docs/cli/user) shows the current identity and the exact capabilities of a token or session, in the model above. Use it to check that a least-privilege token has the intended scope.

## Default capabilities for new users

Each new user gets a system-wide default capability. The shipped default is lenient, for installations without ACLs. With ACLs, you usually tighten it to a minimal baseline, and grant more rights per user or per group, for example from OAuth groups through [Group Rules](/docs/admin/access-control/group-rules).

Two admin commands manage this default:

```bash
# Show the capabilities granted to newly created users
stategraph capabilities default show

# Tighten the default so new users start with plan-only rights
stategraph capabilities default set --plan
```

- `stategraph capabilities default set` takes the same capability flags as token creation, including `--capabilities-json`, but no `--name`.
- `stategraph caps` is an alias for `stategraph capabilities`.
- Both commands need an instance admin. They call `GET /api/v1/caps/default` and `PUT /api/v1/caps/default`, whose body is `{"capabilities": {...}}`.
- A new default applies to users created afterward, not to existing users.

## API

The CLI wraps three endpoints. See the [API Reference](/docs/reference/api/access-tokens#api-keys).

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `POST` | `/api/v1/user/access-tokens` | Create a token. The request body accepts `name` and an optional `capabilities` object. |
| `GET` | `/api/v1/user/access-tokens` | List the tokens of the current user. |
| `POST` | `/api/v1/user/access-tokens/revoke?token_id=<id>` | Revoke a token. |

## Next steps

- [User Commands](/docs/cli/user): the `stategraph user` CLI group
- [Authentication](/docs/admin/access-control): API keys and service accounts
- [Local Authentication](/docs/admin/access-control/local-authentication): email and password user management
- [API Reference](/docs/reference/api): REST API endpoints
