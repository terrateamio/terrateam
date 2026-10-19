---
title: Security
description: API endpoints for security scans: the findings of a state, their summary, scan history, tenant posture over time, and transaction impact.
order: 10
---


These endpoints return the security scan results of states and transactions, and start new scans. See [Security scanning](/docs/infrastructure-as-a-database/security).

- When scanning is off (`STATEGRAPH_SECURITY` is not `true` or `1`), every endpoint answers `503` with `{ "id": "SECURITY_DISABLED" }`. See [Environment variables](/docs/admin/operations/environment-variables).
- For a state that was never scanned, the endpoints answer `200` with empty results, never `404`.

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/states/{state_id}/security/findings` | Findings of the state's latest current scan, with the `scan` record. `?severity` filters; paginated through the `Link` header (`?page`, `?limit`) |
| `GET` | `/api/v1/states/{state_id}/security/findings/summary` | Severity breakdown, `internet_reachable_count`, and `top_checks` for the latest current scan |
| `POST` | `/api/v1/states/{state_id}/security/scan` | Trigger a fresh scan; returns `202` with a task (poll [`/api/v1/tasks/{task_id}`](/docs/reference/api/transactions#tasks)) |
| `GET` | `/api/v1/states/{state_id}/security/scans` | Scan history, newest first; paginated through the `Link` header |
| `GET` | `/api/v1/tenants/{tenant_id}/security/findings/history` | Tenant-wide posture over time, one point per day (`?from`, `?to`, ISO 8601; default the last 30 days), bucketed by severity and blast impact |
| `GET` | `/api/v1/tx/{tx_id}/security/impact` | Findings that the planned change of a transaction adds and resolves, against the latest scan of each affected state. `202` with `{ "status": "computing" }` while the preview scan runs; `404` once the transaction is aborted |
| `GET` | `/api/v1/tx/{tx_id}/security/impact/summary` | Added and resolved finding counts by severity for a transaction |

## Findings

Each finding has these fields:

- `check_id`, `resource_fq_address`, `state_id`, `workspace`, `severity_base`, `severity_effective`, and `fingerprint`.
- When computed: `blast_radius_resource_count`, `blast_radius_modules`, `cross_state_refs`, and `is_internet_reachable`.
- When computed: `source_file`, `source_start_line`, and `source_end_line`, the location of the offending block.
