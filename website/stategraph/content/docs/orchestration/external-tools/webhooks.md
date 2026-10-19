---
title: Webhooks
description: Send HTTP requests to external systems from Stategraph Orchestration hooks and workflow steps, on success or failure, with run context in the payload.
order: 2
---

A webhook in Stategraph Orchestration is a `run` step in a [hook](/docs/reference/orchestration/configuration/hooks) or a [workflow](/docs/reference/orchestration/configuration/workflows) that sends an HTTP request to an external system, with the built-in environment variables in the payload. There is no separate webhooks feature.

## Configuring webhooks

This example in `.stategraph/config.yml` sends a JSON POST with `curl` after an apply operation:

```yaml
hooks:
  apply:
    post:
      - type: run
        cmd: ['curl', '-X', 'POST', '-d', '{"text":"Apply completed"}', 'https://example.com/webhook']
```

## Webhook events

A request can go at these points in a run:

- Before or after a plan or apply operation, one time per operation: use `hooks`.
- Before or after the plan or apply of each directory and workspace: use `workflows` steps.

## Distinguishing between success and failure

`run` steps in `hooks` and `workflows` take `run_on`: `success` (the default), `failure`, or `always`. In a post hook, `run_on` uses the result of the whole operation. In a workflow step, it uses the result of the earlier steps for that directory and workspace.

```yaml
hooks:
  apply:
    post:
      - type: run
        run_on: success
        cmd: ['curl', '-X', 'POST', '-d', '{"text":"Apply succeeded"}', 'https://example.com/webhook']
      - type: run
        run_on: failure
        cmd: ['curl', '-X', 'POST', '-d', '{"text":"Apply failed"}', 'https://example.com/webhook']
```

```yaml
workflows:
  - tag_query: ""
    apply:
      - type: init
      - type: apply
      - type: run
        run_on: success
        cmd: ['curl', '-X', 'POST', '-d', '{"text":"Apply succeeded for directory: $TERRATEAM_DIR"}', 'https://example.com/webhook']
      - type: run
        run_on: failure
        cmd: ['curl', '-X', 'POST', '-d', '{"text":"Apply failed for directory: $TERRATEAM_DIR"}', 'https://example.com/webhook']
```

## Using environment variables in webhooks

The environment variables that you can use in payloads depend on where the `run` step runs:

- In `workflows` steps (per directory and workspace):
    - `TERRATEAM_DIR`: directory being processed
    - `TERRATEAM_WORKSPACE`: workspace in use
    - `TERRATEAM_PLAN_FILE`: path to the plan file
    - `TERRATEAM_ROOT`: root path of the repository
- In `hooks` (once per operation):
    - `TERRATEAM_ROOT`: root path of the repository
    - `TERRATEAM_RESULTS_FILE` (post hooks only): path to a JSON file with the results of every directory and workspace

A `run` step fails with a missing environment variable error when its `cmd` uses a variable that is not set. So do not use the per-directory variables in `hooks`. For the full list and the shape of the results file, see [Environment variables](/docs/orchestration/configuration/environment-variables).

## Securing webhooks

- Use HTTPS for each webhook URL.
- Send a secret token for authentication.
- Sanitize the input on the receiving side.
- Keep tokens in GitHub secrets or GitLab CI/CD variables.

```yaml
hooks:
  apply:
    post:
      - type: run
        cmd: ['curl', '-X', 'POST', '-d', '{"text":"Apply complete", "token":"$WEBHOOK_SECRET_TOKEN"}', 'https://example.com/webhook']
```

## Examples

### Slack notifications via workflows

```yaml
workflows:
  - tag_query: ""
    apply:
      - type: init
      - type: apply
      - type: run
        run_on: success
        cmd: ['curl', '-X', 'POST', '-H', 'Content-Type: application/json', '--data', '{"text":"Apply succeeded for $TERRATEAM_DIR"}', '$SLACK_WEBHOOK_URL']
      - type: run
        run_on: failure
        cmd: ['curl', '-X', 'POST', '-H', 'Content-Type: application/json', '--data', '{"text":"Apply failed for $TERRATEAM_DIR"}', '$SLACK_WEBHOOK_URL']
```

### Custom webhook server

```yaml
hooks:
  plan:
    post:
      - type: run
        run_on: always
        cmd: ['curl', '-X', 'POST', '-H', 'Content-type: application/json', '--data-binary', '@$TERRATEAM_RESULTS_FILE', 'https://hooks.example.com/stategraph-webhook']
```

## Next Steps

- [hooks reference](/docs/reference/orchestration/configuration/hooks): every hook type and key
- [Environment variables](/docs/orchestration/configuration/environment-variables): built-in variables and the results file
- [AI integrations](/docs/orchestration/external-tools/ai-integrations): send results to an LLM from a post hook
