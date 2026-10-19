---
title: Local Authentication
description: Set up email and password sign-in for self-hosted Stategraph, and manage users, passwords, and service accounts.
order: 2
---


Local authentication signs users in to Stategraph with an email and a password, and you manage users, passwords, and service accounts in Stategraph, with no OAuth provider. It is ready for production. For Google Workspace or another identity provider, see [Google OAuth](/docs/admin/access-control/google-oauth) or [OIDC](/docs/admin/access-control/oidc).

## How it works

<figure class="docs-figure">
<div class="docs-mock docs-flow">
<div class="docs-flow-node">Browser</div><div class="docs-flow-node accent">Stategraph server</div><div class="docs-flow-node">PostgreSQL</div><div class="docs-flow-msg c12 right"><span>1. Email and password</span></div><div class="docs-flow-msg c23 right"><span>2. Check the credentials</span></div><div class="docs-flow-msg c12 left"><span>3. Session cookie</span></div><div class="docs-flow-msg c12 right"><span>4. Authenticated requests</span></div>
</div>
<figcaption>The browser sends the email and password to <code>POST /api/v1/login/password</code>.<br> The server checks them in PostgreSQL and sets a session cookie.<br> The cookie authenticates the later requests.</figcaption>
</figure>

## Initial setup

Local authentication is the default. After the first deploy, open your Stategraph URL, for example `http://localhost:8080`, and create the first admin account in the setup wizard. You are then signed in.

Passwords must have 8 to 128 characters. Stategraph enforces no complexity rules.

## User management

### Creating users

An instance admin creates users in the console under **Settings > Admin**. A `users-manage` holder uses `POST /api/v1/users` ([Create user](/docs/admin/access-control/local-authentication#create-user)). Only an instance admin can create an admin, and that admin gets installation-wide admin: the unrestricted `admin` capability. For tenant-level admins, see [Tenants and Administration](/docs/admin/access-control/tenants).

### User roles

| Role | Capabilities |
|------|--------------|
| Admin | Full access: create, edit, and delete users, reset the passwords of users below them, manage all states and tenants, view all settings |
| Regular user | Access assigned tenants, create API keys, manage own states |

### Changing passwords

To change your own password, send the current and the new password to `POST /api/v1/users/change-password?user_id=<your-user-id>` ([Change user password](/docs/admin/access-control/local-authentication#change-user-password)). Your user ID is on **Settings > Account**. An instance admin can also change it under **Settings > Admin**. A change of your own password always needs the current one, whatever capabilities you hold.

An instance admin resets the password of another user under **Settings > Admin**, with no current password, only for users who sign in with a password. Only instance admins see **Settings > Admin**, so a `users-manage` holder uses `POST /api/v1/users/change-password`.

You can reset only a user who holds strictly less authority than you and belongs only to tenants that your grant reaches. See [Who can act on whom](/docs/admin/access-control/tenants).

- An admin resets ordinary users and `users-manage` holders.
- A `users-manage` holder resets ordinary users.
- Below instance admin, peers cannot reset each other. So a stolen session cannot take over an account sideways.
- Instance admins can reset each other, so a locked-out admin can get back in.

### Managing admin access

Instance admins grant or remove installation-wide admin under **Settings > Admin**. Open the **Manage** menu of the user, and choose **Make installation-wide Admin** or **Remove installation-wide Admin**.

Granting it replaces the admin grants that the user holds on some tenants. Removing it later does not restore them, so each tenant must grant the role again under **Settings > Members**. Removing it leaves a tenant-scoped admin grant untouched. To change admin on one tenant, use **Settings > Members** in that tenant (see [Tenants and Administration](/docs/admin/access-control/tenants)).

You cannot remove your own admin privileges, and nobody can remove them from the last installation admin.

### Deleting users

Deleting follows the password reset rule, and instance admins can delete each other. A `users-manage` holder deletes only ordinary users that belong to tenants it manages. An instance admin deletes users under **Settings > Admin**.

Stategraph soft-deletes users: it marks them as deleted in the database, and does not remove them. Their API keys stop working immediately.

## Service accounts (API users)

Service accounts give CI/CD pipelines and automation programmatic access. A service account is a user of type `api`:

- It has no password, so it cannot sign in interactively.
- It is tied to one tenant.
- It shows with its own name in the transaction logs.

Create one in the console on **Settings > API Keys**, under **Service Accounts**. The service account joins your current tenant. Its API token is shown only once.

Through the API:

```bash
curl -X POST http://localhost:8080/api/v1/api-users \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "name": "ci-production",
    "tenant_id": "<tenant-uuid>"
  }'
```

Response:

```json
{
  "user_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

## Authentication flow

### Login flow

1. The user opens Stategraph.
2. If not authenticated, the browser is redirected to the login page.
3. The user enters an email and password.
4. The browser sends `POST /api/v1/login/password`.
5. The server checks the credentials, creates a session token, and sets it as an HTTP-only cookie that authenticates later requests.
6. The browser goes to the console.

### Login endpoint

```bash
POST /api/v1/login/password
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "your-password"
}
```

Response:

```json
{
  "session_token": "eyJhbGciOiJIUzI1NiIs...",
  "success": true
}
```

The `session_token` also works for Bearer authentication.

### Logout

```bash
GET /api/v1/logout
```

Logout clears the session cookie.

## API endpoints

### Authentication endpoints

#### Get login options

```bash
GET /api/v1/login/options
```

Returns the available sign-in methods. When OAuth is configured, the `options` array lists the providers.

Response:

```json
{
  "options": []
}
```

#### Login with password

```bash
POST /api/v1/login/password
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "your-password"
}
```

#### Check setup status

```bash
GET /api/v1/setup/status
```

Returns whether the initial setup is necessary.

Response:

```json
{
  "needs_setup": false
}
```

#### Create first admin

```bash
POST /api/v1/setup/admin
Content-Type: application/json

{
  "email": "admin@example.com",
  "password": "secure-password",
  "name": "Admin User",
  "organization": "Acme"
}
```

Works only when no users exist.

#### Logout

```bash
GET /api/v1/logout
```

### User management endpoints

#### List users

```bash
GET /api/v1/users?type=user&limit=25
```

Query parameters:

- `type`: `user`, `api`, or `system`. Omit it to list every type.
- `search`: case-insensitive substring match against name or email.
- `cursor`: opaque cursor from a previous response's `next_cursor`. Omit it for the first page.
- `limit`: maximum results. Default 25, clamped to the server's maximum.

To fetch the next page, pass `next_cursor` back as `cursor`.

Response:

```json
{
  "users": [
    {
      "id": "f30ed1f9-be44-46a3-9050-03e9561e94f0",
      "name": "John Doe",
      "email": "john@example.com",
      "admin_rights": { "is_instance_admin": false, "is_tenant_admin": false },
      "type": "user",
      "created_at": "2024-01-15T10:30:00Z"
    }
  ],
  "total_count": 10,
  "limit": 25,
  "has_more": false,
  "next_cursor": null
}
```

#### Get user details

```bash
GET /api/v1/users/detail?user_id=<user-id>
```

Response:

```json
{
  "id": "f30ed1f9-be44-46a3-9050-03e9561e94f0",
  "name": "John Doe",
  "email": "john@example.com",
  "admin_rights": { "is_instance_admin": false, "is_tenant_admin": false },
  "type": "user",
  "created_at": "2024-01-15T10:30:00Z"
}
```

The response also includes `auth_origin` (how the user authenticates), and `avatar_url` when available. In `admin_rights`, which the users list and `PUT /api/v1/users/update` also report, `is_instance_admin` is admin over the whole installation and `is_tenant_admin` over named tenants only. They are never both true.

#### Create user

```bash
POST /api/v1/users
Content-Type: application/json

{
  "name": "Jane Doe",
  "email": "jane@example.com",
  "password": "secure-password",
  "is_instance_admin": false
}
```

`is_instance_admin` grants the installation-wide admin capability at creation. This endpoint cannot create a tenant-scoped admin. To make one, use the tenant members API afterwards.

Response:

```json
{
  "id": "a1b2c3d4-5678-90ab-cdef-1234567890ab",
  "name": "Jane Doe",
  "email": "jane@example.com",
  "is_instance_admin": false
}
```

#### Update user

```bash
PUT /api/v1/users/update?user_id=<user-id>
Content-Type: application/json

{
  "name": "Jane Smith",
  "email": "jane.smith@example.com"
}
```

From an admin session, `is_instance_admin` can also be sent, to grant or revoke the installation-wide admin capability with the same write and the same refusals as `POST /api/v1/users/set-instance-admin`. Revoking it from the last installation admin returns `400 CANNOT_REMOVE_LAST_ADMIN`, and revoking your own returns `400 CANNOT_ACT_ON_SELF`. Either refusal discards the whole update.

#### Delete user

```bash
DELETE /api/v1/users/delete?user_id=<user-id>
```

Response:

```json
{
  "id": "a1b2c3d4-5678-90ab-cdef-1234567890ab",
  "deleted": true
}
```

#### Change user password

```bash
POST /api/v1/users/change-password?user_id=<user-id>
Content-Type: application/json

{
  "new_password": "new-secure-password",
  "current_password": "old-password"
}
```

`current_password` is required only when you change your own password.

#### Set installation admin status

```bash
POST /api/v1/users/set-instance-admin?user_id=<user-id>
Content-Type: application/json

{
  "is_instance_admin": true
}
```

Sets, not toggles, the installation-wide `admin` capability. `true` writes an unrestricted grant, replacing any tenants allow-list the user held. `false` removes an unrestricted grant and leaves a tenant-scoped one untouched. Removing it from the last installation admin returns `400 CANNOT_REMOVE_LAST_ADMIN`, and removing your own returns `400 CANNOT_ACT_ON_SELF`, whoever else holds one.

### Service account endpoints

#### Create service account

```bash
POST /api/v1/api-users
Content-Type: application/json

{
  "name": "ci-production",
  "tenant_id": "<tenant-uuid>"
}
```

Response:

```json
{
  "user_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

## Creating API keys

Create API keys for CLI and Terraform access in the console under **Settings > API Keys**. The key is shown only once. The CLI reads it from `STATEGRAPH_API_KEY`:

```bash
export STATEGRAPH_API_KEY="<your-api-key>"
stategraph states list --tenant <tenant-id>
```

With an existing API key, `stategraph user access-tokens create` creates least-privilege tokens, such as apply-only on specific states. Service accounts can get the same tokens. See [Access Tokens and Capabilities](/docs/admin/access-control/access-tokens).

## Security considerations

- Session cookies are HTTP-only, so JavaScript cannot read them.
- Session tokens are JWTs signed with a secret key.
- Use HTTPS in production to protect credentials and session tokens in transit.
- Use strong passwords, and enforce a password policy in your organization.
- Use service accounts for CI/CD, not personal credentials.
- Grant admin access only when necessary. Review the user list and admin access regularly.
- Review the transaction logs for unusual activity.

## Transitioning to OAuth

1. Set the OAuth environment variables. See [Google OAuth](/docs/admin/access-control/google-oauth) or [OIDC](/docs/admin/access-control/oidc).
2. Restart Stategraph.

After the change:

- Existing local users stay in the database, and existing API keys keep working.
- Stategraph creates each OAuth user at the first sign-in.
- OAuth sign-in replaces the local login page. Local users cannot sign in with a password until you turn off OAuth.

## Next steps

- [Configure Google OAuth](/docs/admin/access-control/google-oauth) for SSO
- [Configure OIDC](/docs/admin/access-control/oidc) for other providers
- [Set up Infrastructure as a Database](/docs/infrastructure-as-a-database/setup)
- [Set up CI/CD with service accounts](/docs/admin/access-control#cicd-setup)
