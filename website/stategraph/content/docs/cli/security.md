---
title: Security Commands
description: CLI commands for Stategraph security scanning: findings and scan history of a state, tenant posture, and change impact.
order: 15
---


The `stategraph security` commands start scans and show the results: the findings and scan history of a state, the security posture of a tenant, and the security impact of a planned change.

Scanning runs on the server. It needs a configured checkov binary, and the feature must not be disabled. When scanning is disabled, the commands say so and do not fail. For the server setup, see [Enable security scanning](/docs/admin/self-hosting/security-scanning).

## Commands

| Command | Description |
|---------|-------------|
| `stategraph security findings list` | Findings of the latest current scan of a state |
| `stategraph security findings summary` | Severity counts and top failing checks of the latest current scan of a state |
| `stategraph security scans list` | Scan history of a state, newest first |
| `stategraph security scan` | Start a new current scan of a state in the background |
| `stategraph security history` | Security posture of a tenant, one entry per day (oldest first), with severity counts |
| `stategraph security impact summary` | Added and resolved finding counts per severity, for the planned change of a transaction |
| `stategraph security impact findings` | Added and resolved findings for the planned change of a transaction, as JSON |

Common options:

- All commands take `--api-base` (or `STATEGRAPH_API_BASE`).
- All except `scan` and `impact findings` accept `--format=table|json|simple`. Default: `table`.
- State commands require `--state` (a UUID).
- `history` requires `--tenant`, a UUID (or `STATEGRAPH_TENANT_ID`).
- The `impact` commands take `--tx` (or `STATEGRAPH_TX_ID`).

## stategraph security findings list

```bash
stategraph security findings list --state <state-id> [--severity <level>] [--limit <n>]
```

- `--severity` filters by effective severity, for example `critical`, `high`, `medium`, or `low`. Default: all severities, including unknown.
- `--limit` returns only the first N rows.

Output:

```text
check_id    severity_effective  resource_fq_address            blast  fingerprint
----------  ------------------  -----------------------------  -----  -----------
CKV_AWS_21  high                module.web.aws_s3_bucket.logs  12     3f1c9a2b
```

In the default table:

- `severity_effective` is the scanner severity after context adjustment, for example higher when the resource is reachable from the internet.
- `blast` is the number of resources in the blast radius of the finding, after enrichment.
- `fingerprint` shows only its first characters.

`--format json` gives the full finding objects, with the `scan` envelope and `total_count`. A state that was never scanned returns no findings, not an error.

## stategraph security findings summary

```bash
stategraph security findings summary --state <state-id>
```

Output:

```text
metric              value
------------------  -----
total               14
internet_reachable  3
critical            1
high                5
medium              6
low                 2
unknown             0
top:CKV_AWS_21      4
top:CKV_AWS_18      3
```

If the state has no completed current scan yet, the command says so and exits non-zero.

## stategraph security scans list

```bash
stategraph security scans list --state <state-id> [--limit <n>]
```

The table shows `scanned_at`, `kind`, `status`, `scanner`, `findings`, `scan_id`, and `triggered_by`:

- `kind` is `current` for a baseline scan of the HCL of the state, or `planned` for a scan of a planned change in a transaction.
- `status` is `running`, `completed`, or `failed`.

## stategraph security scan

The command queues the scan, prints the task ID, and exits.

```bash
stategraph security scan --state <state-id>
```

Output:

```text
Security scan queued (task 7c9e6679-7425-40de-944b-e07fc1f90ae7). Re-run `stategraph security findings summary --state <state-id>` once it completes.
```

## stategraph security history

```bash
stategraph security history --tenant <tenant-id> [--from <iso8601>] [--to <iso8601>]
```

`--from` and `--to` set the start and end of the history window, in ISO 8601. Defaults: 30 days ago, and now.

The table shows `date`, `total`, `critical`, `high`, `medium`, `low`, `info`, and `unknown`. The JSON form adds `states_total`, `states_scanned`, `last_scanned_at`, and the blast-radius breakdown of each day.

## stategraph security impact

The `impact` commands compare the planned change of a transaction with the latest current scan of each affected state, at plan time. `stategraph tf plan` prints the summary when it is ready within `--security-wait` seconds. These commands get it later.

While the computation runs, both `impact` commands print `Security impact not yet ready for this transaction; try again shortly.`

### stategraph security impact summary

```bash
stategraph security impact summary --tx <tx-id>
```

Output:

```text
metric                        value
----------------------------  --------------------
source                        planned
computed_at                   2026-09-10T12:47:32Z
states_affected               1
cross_boundary_finding_count  0
added:critical                0
added:high                    1
added:medium                  0
added:low                     0
added:info                    0
added:unknown                 0
resolved:critical             0
resolved:high                 0
resolved:medium               2
resolved:low                  0
resolved:info                 0
resolved:unknown              0
```

`source` is `planned` when computed at plan time from a preview, and `commit` when computed after apply.

### stategraph security impact findings

```bash
stategraph security impact findings --tx <tx-id>
```

## Next Steps

- [Security scanning](/docs/infrastructure-as-a-database/security): findings in the plan, and posture over time.
- [Enable security scanning](/docs/admin/self-hosting/security-scanning): turn on scanning in a self-hosted deployment.
- [Terraform Commands](/docs/cli/tf): `--security-wait` on `tf plan`.
- [Transactions](/docs/cli/transactions): find a transaction ID.
- [States](/docs/cli/states): find a state ID.
