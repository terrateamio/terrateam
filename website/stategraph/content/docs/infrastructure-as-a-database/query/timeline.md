---
title: Timeline
description: See the transaction history of your Terraform states in the Timeline. Find who changed what and when, and inspect and tag changes.
order: 9
---


The Timeline lists the transactions of your Terraform states in time order: who changed what, and when.

Each operation that changes a state is a transaction: `terraform apply` operations, state imports, resource changes, and state migrations. In the console, open **Insights > Timeline**.

## List transactions with the CLI

1. Get your tenant ID:

```bash
stategraph user tenants list
```

Output:

```
id                                    name
------------------------------------  ------
550e8400-e29b-41d4-a716-446655440000  my-org
```

2. List the transactions:

```bash
stategraph tx list --tenant 550e8400-e29b-41d4-a716-446655440000
```

Response:

```json
{
  "results": [
    {
      "id": "455fe705-f27f-4335-9355-dbe8f14098df",
      "created_at": "2024-01-15T10:30:00Z",
      "created_by": "f30ed1f9-be44-46a3-9050-03e9561e94f0",
      "completed_at": "2024-01-15T10:30:05Z",
      "completed_by": "f30ed1f9-be44-46a3-9050-03e9561e94f0",
      "state": "committed",
      "tags": {
        "desc": "Backend update"
      }
    }
  ]
}
```

3. Get the transaction logs:

```bash
stategraph tx logs list --tx 455fe705-f27f-4335-9355-dbe8f14098df
```

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

## Transaction properties

| Property | Description |
|----------|-------------|
| `id` | Unique transaction ID |
| `created_at` | Start time |
| `created_by` | User or system that started it |
| `completed_at` | End time |
| `completed_by` | User or system that completed it |
| `state` | Lifecycle state, such as `open`, `committed`, or `aborted`. See [Transaction states](/docs/infrastructure-as-a-database/transactions#transaction-states). |
| `tags` | Metadata tags, such as pipeline information or the commit |

## Log entries

| Field | Description |
|-------|-------------|
| `action` | Type of change (`state_set`, `state_delete`, `hcl_set`, `hcl_delete`, `tfvar_set`, `tfvar_delete`, `tfvar_ephemeral`, `file_set`, `file_delete`, `refresh`) |
| `object_type` | What changed (`instance`, `resource`, `output`, `provider`, `state_metadata`, `hcl`, `tfvar`, `file`, `check_result`, `check_result_entry`, `refresh`) |
| `state_id` | Affected state |
| `data` | Change details |

## Use cases

- Audit trail: review user activity and record the changes for compliance.
- Debugging and incidents: find when a change occurred, what changed, who made it, and its context (tags, pipeline). For an incident, look for related transactions just before its time.
- Rollback planning: find and review the transaction that caused a problem. Then plan, run, and verify the rollback.

## Transaction tags

When you run Terraform from CI/CD, add tags:

```hcl
# In your Terraform backend config
# Tags are passed via the API during state operations
```

Common tags:

| Tag | Example | Purpose |
|-----|---------|---------|
| `pipeline` | `github-actions` or `gitlab-ci` | CI/CD system |
| `commit` | `abc123` | Git commit |
| `branch` | `main` | Git branch |
| `run_id` | `12345` | CI run ID |
| `triggered_by` | `push` | Trigger type |

To create a transaction with tags:

```bash
stategraph tx create \
  --tenant 550e8400-e29b-41d4-a716-446655440000 \
  --tag pipeline=github-actions \
  --tag commit=abc123 \
  --tag branch=main
```

Use tags that give each transaction context:

```json
{
  "tags": {
    "pipeline": "terraform-ci",
    "commit": "abc123",
    "ticket": "INFRA-456",
    "environment": "production"
  }
}
```

## Best practices

- Check the Timeline weekly for unexpected or unauthorized changes, and make sure that CI/CD transactions complete.
- Export transaction data periodically for monthly audit reports, compliance records, and change management records.

## Stuck transactions

Find the open transactions:

```bash
stategraph tx list --tenant 550e8400-e29b-41d4-a716-446655440000 | \
  jq '.results[] | select(.state == "open")'
```

Abort a stuck transaction:

```bash
stategraph tx abort --tx 455fe705-f27f-4335-9355-dbe8f14098df
```

## Next steps

- [Search](/docs/infrastructure-as-a-database/query/search): find resources quickly.
- [Blast Radius](/docs/infrastructure-as-a-database/query/blast-radius): analyze the impact of a change.
