---
title: Audit trail
description: Query the history of every Stategraph Orchestration run by user, directory, and date, and trace state changes through the transaction timeline.
order: 8
---


Stategraph keeps two records of change. Together they show who changed what, when, and through which pull request:

- Stategraph Orchestration records each run in your repositories.
- Infrastructure as a Database records each change to a state as a transaction.

## Orchestration audit trail

In the console, the audit trail is under **Orchestration > Audit**. It lists each plan, apply, and drift run from GitHub and GitLab together, up to the 1,000 most recent runs from each, and exports as CSV or JSON. Use it as evidence for internal policy and external audits, to find the run that caused a problem, and to see change patterns and bottlenecks over time.

Each run records:

- Timestamp: when the run executed.
- User: who started it.
- Operation type: plan, apply, or drift.
- Directories: the directories and workspaces that the run touched.
- Status: success or failure.
- Output: the logs and error messages of the run.

### Querying the audit trail

You can also query the run history with SQL or with the API.

With SQL, runs are rows in the `github_work_manifests` and `gitlab_work_manifests` tables. Both tables have the same columns. On GitLab, `pull_number` holds the merge request number. Query them with `stategraph sql query`:

```bash
stategraph sql query "SELECT created_at, username, run_type, state, repo_name, pull_number FROM github_work_manifests WHERE username = 'jane' ORDER BY created_at DESC LIMIT 20"
```

With the API, the run listing endpoints, `GET /api/v1/github/installations/{installation_id}/work-manifests` and its [GitLab equivalent](/docs/reference/api/vcs-installations#list-work-manifests), take a query in the `q` parameter. See [GitHub installations](/docs/reference/api/vcs-installations#list-work-manifests). Queries use the syntax of [tag queries](/docs/reference/orchestration/configuration/tag-queries), with these keys: `branch`, `created_at`, `dir`, `environment`, `id`, `kind`, `pr`, `repo`, `state`, `type`, `user`, and `workspace`.

Operators:

- `and`: every condition must match.
- `or`: at least one condition must match.
- `not`: negates a condition.
- `..`: a range of values, for example a date range.
- `<key>:<value>`: matches a key and value.

Examples:

- `created_at:2023-11-01..2023-12-01`: each run from November 1 to November 30, 2023, inclusive.
- `created_at:2023-11-01..2023-12-01 and user:jane`: the same period, started by the user `jane`.
- `created_at:2023-11-01..2023-12-01 and user:jane and (dir:envs/prod/s3 or dir:envs/prod/iam)`: the same, only for runs that touched `envs/prod/s3` or `envs/prod/iam`.

## Transaction timeline

Each Infrastructure as a Database transaction records:

- the user who created it and the user who completed it
- timestamps and tags
- a log of each object that the transaction set or deleted

In the console, **Timeline** shows these transactions. With the CLI, `stategraph tx list --tenant <tenant-id>` lists transactions, and `stategraph tx logs list --tx <tx-id>` shows what one changed. Tag transactions from CI with the pipeline, commit, and branch, so that each state change leads back to its pull request. See [Timeline](/docs/infrastructure-as-a-database/query/timeline) and the [transactions reference](/docs/cli/transactions).

## Next steps

- [Security best practices](/docs/orchestration/security): the controls that the audit trail helps you verify.
- [Timeline](/docs/infrastructure-as-a-database/query/timeline): state transactions in the console.
- [Transactions reference](/docs/cli/transactions): list, inspect, and abort transactions from the CLI.
