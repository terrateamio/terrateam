---
title: Capabilities Commands
description: Use the stategraph capabilities commands to set the default capabilities of new users and to grant capabilities by identity provider group.
order: 14
---


The `stategraph capabilities` commands set the system-wide default capabilities of new users, and manage group rules that grant capabilities to the members of an identity provider group at login. `stategraph caps` is an alias.

For the capability model, see [Access tokens and capabilities](/docs/admin/access-control/access-tokens). For identity provider groups, see [Group rules](/docs/admin/access-control/group-rules).

## Commands

| Command | Description |
|---------|-------------|
| `stategraph capabilities default show` | Show the default capabilities of new users |
| `stategraph capabilities default set` | Set the default capabilities of new users |
| `stategraph capabilities group create` | Create a group rule |
| `stategraph capabilities group list` | List the group rules |
| `stategraph capabilities group delete` | Delete a group rule by ID |

Each command takes `--api-base` (or `STATEGRAPH_API_BASE`) and `--format` (`table` by default, `json`, or `simple`). The `group` commands also take `--tenant` (or `STATEGRAPH_TENANT_ID`).

## Capability flags

`default set` and `group create` take the capability flags of [`stategraph user access-tokens create`](/docs/cli/user), with the scope differences after the table.

| Flag | Description |
|------|-------------|
| `--admin` | Grant the admin capability. |
| `--plan` | Grant the plan capability. Narrow it with `--plan-modified` / `--plan-pulled-in`. |
| `--plan-modified <STATE_ID=PATTERN>` | Limit plan to the directly modified resources in a state that match PATTERN. Repeatable. |
| `--plan-pulled-in <STATE_ID=PATTERN>` | Limit the resources that plan pulls in from a state, as cone or blast dependencies, to those that match PATTERN. Repeatable. |
| `--apply` | As `--plan`, for apply. |
| `--apply-modified <STATE_ID=PATTERN>` | As `--plan-modified`, for apply. |
| `--apply-pulled-in <STATE_ID=PATTERN>` | As `--plan-pulled-in`, for apply. |
| `--users-manage` | Grant the users-manage capability. |
| `--capabilities-json <json>` | Raw capabilities JSON object. You cannot use it with the individual flags. |

A pattern is one of:

- `*`, for the whole state: `sid=*`
- a prefix: `sid=module.foo.*`
- a leading `!`, to deny: `sid=!module.foo.output.*`

Repeated flags add their patterns together.

`default set` also accepts `--admin-tenant`, `--plan-tenant`, `--apply-tenant`, `--users-manage-tenant`, `--sudo-user`, `--access-token-create`, and `--access-token-refresh`, as `access-tokens create` does. `group create` does not: each capability that a rule grants is scoped to the `--tenant` of the rule.

## stategraph capabilities default show

```bash
stategraph capabilities default show
```

The output is the `field | value` capability table that `stategraph user whoami` prints:

```text
field                 value
--------------------  -----
capabilities
  admin                 no
  access-token-create   no
  access-token-refresh  no
  plan                  yes
    tenants             all
    states              all
    subgraph            all
  apply                 yes
    tenants             all
    states              all
    subgraph            all
  sudo                  no
  users-manage          no
```

## stategraph capabilities default set

Replaces the default capabilities of new users, and prints the new default as `default show` does.

- Give at least one capability flag or `--capabilities-json`. With none, the command fails.
- The new default applies to users created after it, not to existing users.

```bash
# New users start with plan-only rights
stategraph capabilities default set --plan
```

## stategraph capabilities group create

Each rule is scoped to a tenant. It grants capabilities only in that tenant, and the admins of that tenant manage it. An installation admin can manage the rules of any tenant.

```bash
stategraph capabilities group create --tenant <tenant-id> [capability flags] [--description <text>] <condition-json>
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `<condition-json>` | Yes | The rule condition, a JSON object: `{"group": <glob>}`, `{"any": [<cond>, ...]}`, or `{"all": [<cond>, ...]}`. A group matches by exact name, or by a prefix glob that ends in `*`: `{"group": "eng-*"}` matches `eng-web`, `eng-db`, and so on. |

### Options

| Option | Required | Description |
|--------|----------|-------------|
| `--tenant` | Yes | Tenant ID (UUID), or set `STATEGRAPH_TENANT_ID`. |
| `--description` | No | A description for people to read. |
| `--capabilities-json` | No | Raw capabilities JSON to grant. Refused if the grant reaches beyond `--tenant`. |

The [capability flags](#capability-flags) select what the rule grants.

### Example

Plan-only rights for everyone, apply for engineers, and per-team ownership of two states:

```bash
TENANT=<tenant-id>

# Baseline for everyone: can plan, nothing else.
stategraph caps default set --plan

# Anyone in an "eng-*" group may also apply within this tenant.
stategraph caps group create '{"group":"eng-*"}' --tenant "$TENANT" \
  --apply --description "Engineers may apply"

# Anyone in "platform-admins" is an admin of this tenant.
stategraph caps group create '{"group":"platform-admins"}' --tenant "$TENANT" \
  --admin --description "Platform admins"

# team-a owns the prod-network state: full plan + apply on it, nothing elsewhere.
stategraph caps group create '{"group":"team-a"}' --tenant "$TENANT" \
  --plan-modified '<prod-network-state-id>=*' --apply-modified '<prod-network-state-id>=*' \
  --description "team-a owns prod-network"

# team-b owns the prod-db state.
stategraph caps group create '{"group":"team-b"}' --tenant "$TENANT" \
  --plan-modified '<prod-db-state-id>=*' --apply-modified '<prod-db-state-id>=*' \
  --description "team-b owns prod-db"
```

Output:

```text
id
------------------------------------
9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d
```

## stategraph capabilities group list

```bash
stategraph capabilities group list --tenant <tenant-id>
```

The default table shows `id`, `created_at`, `condition`, and `description`. `--format json` gives the full rule objects, which also include `created_by` and the `grant` capabilities object.

## stategraph capabilities group delete

```bash
stategraph capabilities group delete --tenant <tenant-id> <rule-id>
```

The command prints the `id` of the deleted rule.

## Next steps

- [Access tokens and capabilities](/docs/admin/access-control/access-tokens): the capability model and tokens.
- [Group rules](/docs/admin/access-control/group-rules): identity provider groups and capabilities.
- [User Commands](/docs/cli/user): `whoami` shows the capabilities of a session.
- [Tenants and administration](/docs/admin/access-control/tenants): installation and tenant admins.
