---
title: Stacks
description: API endpoint that returns the stacks of a pull request: their definitions, dependencies, dirspaces, execution order, and plan and apply status.
order: 12
---


The stacks endpoint returns the stacks of a pull request, and how Orchestration will process the infrastructure changes in it. A stack is a logical group of Terraform or OpenTofu resources that you plan and apply together. Stacks:

- Manage the dependencies between infrastructure components.
- Coordinate changes across more than one directory.
- Implement layered infrastructure patterns.
- Keep a consistent order of operations.

See the [Stacks guide](/docs/orchestration/workflows/advanced/stacks) and the [stacks configuration reference](/docs/reference/orchestration/configuration/stacks).

## Get pull request stacks

```text
GET /api/v1/{vcs}/installations/{installation_id}/repos/{repo_id}/prs/{pull_request_id}/stacks
```

Returns the stack configuration and status of a pull request. Status codes: `200`, `403`.

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `vcs` | string | Yes | VCS provider: `github` or `gitlab` |
| `installation_id` | string | Yes | The installation identifier |
| `repo_id` | string | Yes | The repository identifier |
| `pull_request_id` | string | Yes | The pull request number, without `#` on GitHub or `!` on GitLab |

For GitLab, use `gitlab` for `{vcs}`, the group ID for `{installation_id}`, the project ID for `{repo_id}`, and the merge request number for `{pull_request_id}`.

```bash
curl -X GET \
  "https://app.stategraph.cloud/api/v1/github/installations/{installation_id}/repos/{repo_id}/prs/{pull_request_id}/stacks" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

The response (schema `stacks`) includes:

- The stack definitions.
- The stack graph: the dependencies that set the execution order, that is, which stacks must complete before others can start.
- The dirspaces (directory and workspace pairs) of each stack.
- The status of each stack (pending, running, completed, or failed), and its plan and apply status.

Use it to:

- Coordinate deployments from CI/CD.
- Show the status of stacks across pull requests in a dashboard.
- Build tools that show the dependencies between stacks.
- Start actions when a stack changes state.
