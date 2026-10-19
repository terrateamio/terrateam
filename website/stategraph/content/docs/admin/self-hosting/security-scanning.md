---
title: Enable security scanning
description: Turn on checkov security scanning on a self-hosted Stategraph server with STATEGRAPH_SECURITY, and set how often each state is scanned.
order: 8
---


Security scanning on a [self-hosted](/docs/admin/self-hosting) server scans each state with checkov, and keeps the findings and the scan history. It is off by default. The console, the API, and the `stategraph security` commands show the findings: see [Security scanning](/docs/infrastructure-as-a-database/security).

## Enable scanning

Set `STATEGRAPH_SECURITY=1` in the server container environment, and recreate the container:

```bash
# .env
STATEGRAPH_SECURITY=1
```

```bash
docker compose up -d
```

Scanning runs on the server. The Stategraph container has a pinned checkov release on `PATH`, where the server finds it, so you install nothing else. Without the binary, scans fail with a scanner-not-found error, and do not report a clean state.

While scanning is off:

- The security endpoints answer `503` with `{ "id": "SECURITY_DISABLED" }`.
- The server reports `capabilities.security.enabled` as `false`.
- The `stategraph security` commands say so, and do not fail.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `STATEGRAPH_SECURITY` | off | The switch: `true` or `1` turns scanning on |
| `STATEGRAPH_SECURITY_SCHEDULE_HOURS` | `24` | How often the schedule scans each state again |
| `STATEGRAPH_SECURITY_EVENT_DEBOUNCE_HOURS` | `1` | Minimum gap before an apply starts another scan |

## Verify

```bash
curl -H "Authorization: Bearer $STATEGRAPH_API_KEY" \
  https://stategraph.example.com/api/v1/capabilities
```

```json
{ "security": { "enabled": true } }
```

Then start a scan for a state, and list its findings:

```bash
stategraph security scan --state <state-id>
stategraph security findings summary --state <state-id>
```

## Scanning in pull requests

On a pull request, Stategraph Orchestration scans plans with its own `checkov` workflow step in `.stategraph/config.yml`. The step runs on your GitHub Actions or GitLab CI runner, not on the server, and needs no server variable:

```yaml
workflows:
  - tag_query: ""
    plan:
      - type: init
      - type: plan
      - type: checkov
```

See the [workflows reference](/docs/reference/orchestration/configuration/workflows).

## Next steps

- [Security scanning](/docs/infrastructure-as-a-database/security): findings, posture over time, and blast radius.
- [Security commands](/docs/cli/security): the CLI reference.
- [Environment variables](/docs/admin/operations/environment-variables)
