---
title: Support
description: Contact Stategraph support, and send the pull request, patch, configuration, and logs that support needs to reproduce a problem.
order: 1
---


Contact Stategraph support, and send the context that it needs to reproduce your problem. Support cannot see your pull requests, CI, or self-hosted server.

## Get in touch

| Channel | Use it for | Link |
| --- | --- | --- |
| Community Slack | Fastest response, general questions, quick debugging | [stategraph.com/slack](https://stategraph.com/slack) |
| Email | Private details, account and billing questions, log attachments | [support@stategraph.com](mailto:support@stategraph.com) |
| GitHub issues | Reproducible bugs and feature requests | [stategraph/stategraph/issues](https://github.com/stategraph/stategraph/issues) |
| Pull request comment | Stategraph Cloud only: logs your message on the server, with no reply | [`stategraph feedback <message>`](/docs/reference/orchestration/commands/feedback) |

## Before you write

For a problem with an Orchestration run on a pull request, two checks solve many problems:

- Read the Stategraph comment on the pull request. It states why the run stopped, for example an access control denial, a lock of another pull request, or a configuration parse error.
- Comment `stategraph repo-config` on the pull request, and check the evaluated configuration. For the meaning of each field, see the [Configuration reference](/docs/reference/orchestration/configuration/version).

## What to include

For an Orchestration run, send items 1 to 6. On a self-hosted server, also send item 7. For another problem, send the steps that you ran, the full output, and your Stategraph version.

### 1. Repository and pull request number

Give the full URL, for example `https://github.com/acme/infra/pull/482` or `https://gitlab.com/acme/infra/-/merge_requests/482`.

For a private repository, give the `owner/repo` or `group/project` path and the number: `#482` on GitHub, `!482` on GitLab. Support cannot find a pull request from a screenshot.

### 2. What you expected to happen

One or two sentences. Example: "`stategraph plan` should run against `prod/us-east-1` because that directory changed in the pull request."

### 3. What actually happened

Copy the full Stategraph comment and any run ID as text, not a cropped screenshot.

### 4. The pull request patch

Orchestration matches the changed files in the patch against `when_modified`, `dirs`, and tag queries.

#### GitHub

```bash
gh pr diff <PR_NUMBER> --repo <OWNER>/<REPO> --patch > pr-<PR_NUMBER>.patch
```

Without the `gh` CLI, append `.patch` to the pull request URL:

```text
https://github.com/<OWNER>/<REPO>/pull/<PR_NUMBER>.patch
```

#### GitLab

Append `.patch` to the merge request URL:

```text
https://gitlab.com/<GROUP>/<PROJECT>/-/merge_requests/<MR_NUMBER>.patch
```

### 5. The repo-config output

Comment on the pull request:

```text
stategraph repo-config
```

Orchestration answers with a **Repository Config** comment: the configuration sources, and the fully evaluated YAML after the config builder, indexer, and overrides. It often differs from the committed `.stategraph/config.yml`. Expand its **Details** block, and copy the full comment. See [repo-config](/docs/reference/orchestration/commands/repo-config).

### 6. The CI logs

- The status check on the pull request links to the run in the console.
- On GitHub, that page (**View run** and the run ID) and each failure comment link to the workflow run.
- On GitLab, the pipeline and its jobs are on the **Pipelines** tab of the merge request.

#### GitHub

```bash
gh run view <RUN_ID> --repo <OWNER>/<REPO> --log > stategraph-run-<RUN_ID>.log
```

In the browser, select **Download log archive** in the **...** menu at the top right of the workflow run, and attach the zip file.

`gh run view <RUN_ID> --log-failed` gives a smaller log of a failed run, without the setup steps that support often needs.

#### GitLab

Open the failed job and use **Download** on the job log, or append `/raw` to the job URL.

### 7. Server logs (self-hosted only)

Send the server log around the failure, with your Stategraph version or image tag.

#### Docker Compose

```bash
docker compose logs server > stategraph-server.log
```

#### Kubernetes

```bash
kubectl logs -n stategraph -l app.kubernetes.io/name=stategraph --since=1h > stategraph-server.log
```

#### AWS ECS

```bash
aws logs tail /ecs/<name> --region <region> --since 1h > stategraph-server.log
```


!!! warning "Remove secrets before you send"
    Patches and logs can contain cloud credentials, tokens, and internal hostnames. Before you attach them, replace each secret with `REDACTED`. Send sensitive data by email, not in Slack or a GitHub issue.

## Request template

Copy this into your message, and fill it in.

```markdown
**Repository / pull request:** https://github.com/OWNER/REPO/pull/NUMBER or https://gitlab.com/GROUP/PROJECT/-/merge_requests/NUMBER
**Deployment:** Stategraph Cloud | Self-hosted (version: X.Y.Z)
**Command that failed:** stategraph plan

**Expected:**
...

**Actual:**
...

**Attached:**
- [ ] pull request patch
- [ ] `stategraph repo-config` comment
- [ ] CI logs
- [ ] server logs (self-hosted only)
```
