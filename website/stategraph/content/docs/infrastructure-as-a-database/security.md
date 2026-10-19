---
title: Security scanning
description: Scan infrastructure with checkov: findings for each change at plan time, posture over time, and gates on pull requests.
order: 9
---


Stategraph scans your infrastructure with [checkov](https://www.checkov.io/) in Infrastructure as a Database, and can run it in a Stategraph Orchestration workflow step. With the step, a pull request fails or waits for approval when the plan adds a misconfiguration.

## Scanning in Infrastructure as a Database

Stategraph runs two types of scan:

- A `current` scan of the HCL of each state, on a schedule.
- A `planned` scan of the planned change of each transaction, at plan time.

A finding has the checkov check ID, the resource address, and an effective severity: the scanner's severity adjusted for context, for example raised for a resource reachable from the internet.

On a self-hosted server, scanning is off by default: see [Enable security scanning](/docs/admin/self-hosting/security-scanning). Where scanning is disabled, the security commands say so instead of failing.

### Findings in the plan

After the diff, `stategraph tf plan` prints the security impact of the change. The impact is the findings that the change adds and resolves, compared with the latest current scan of each affected state. The plan waits up to three seconds for it. Change the wait with `--security-wait` or `STATEGRAPH_SECURITY_WAIT_SECONDS`, or skip it with `--skip-security`.

If the impact is not ready in time, the plan points to the impact commands. Get it later with the transaction ID:

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

`stategraph security impact findings --tx <tx-id>` prints the added and resolved findings as JSON. While the computation runs, both commands report that the impact is not ready yet.

### Current findings for a state

Get the severity rollup and top failing checks for a state's latest current scan:

```bash
stategraph security findings summary --state <state-id>
```

List the findings, optionally by severity:

```bash
stategraph security findings list --state <state-id> --severity high
```

Each row has the check ID, effective severity, resource address, number of resources in the blast radius of the finding, and a fingerprint. `--format json` returns the full finding objects.

`stategraph security scans list --state <state-id>` shows the scan history. `stategraph security scan --state <state-id>` queues a new scan in the background. Run the summary again when it completes.

### Posture over time

Track the tenant's security posture day by day:

```bash
stategraph security history --tenant <tenant-id> --from 2026-08-01T00:00:00Z
```

The table has one row per day, with the total and the count per severity, for the last 30 days by default. In the console, the **Overview** screen under **Security** charts the same history for all states of the tenant.

## Checkov in the pull request

To run checkov against the generated plan, add the `checkov` step after `plan` in `.stategraph/config.yml`:

```yaml
workflows:
  - tag_query: ''
    plan:
      - type: init
      - type: plan
      - type: checkov
```

With the step:

1. The `checkov` step scans the plan file from `init` and `plan` for misconfigurations and policy violations.
2. If checkov finds issues, it exits non-zero and the plan fails.
3. The plan results on the pull request include the checkov output, with details of each finding.
4. If the scan is clean, the plan succeeds, and you review and apply it as usual.

<figure class="docs-figure" data-vcs="github">
<div class="docs-mock">
<div class="docs-mock-bar"><span class="docs-mock-avatar"><img src="/assets/logo-symbol.svg" alt=""></span><span class="vcs-github docs-mock-author">Stategraph GitHub App</span><span class="vcs-github docs-mock-badge">bot</span><span class="vcs-gitlab docs-mock-author">Access token user</span><span>commented</span><span class="docs-vcs-switch" role="group" aria-label="Provider"><button type="button" data-vcs-set="github" aria-pressed="true">GitHub</button><button type="button" data-vcs-set="gitlab" aria-pressed="false">GitLab</button></span></div><div class="docs-mock-body"><div class="docs-mock-h">Plans ✖️</div><p>Running plans <strong>FAILED</strong>. See <strong>Stategraph Plan Output</strong>.</p><p>After resolving the issue, run <code>stategraph plan</code> to execute the plan operation again.</p><div class="docs-mock-h">Stategraph Plan Output ✖️</div><details open><summary>Expand for plan output details</summary><div class="docs-mock-details"><div class="docs-mock-h small">edge | default | ✖️</div><div class="docs-mock-kv"><div><strong>Dir</strong>: edge</div><div><strong>Workspace</strong>: default</div><div><strong>Success</strong>: ✖️</div></div><div class="docs-mock-kv"><div><strong>Step</strong>: tf/plan</div><div><strong>Success</strong>: 👍</div></div><pre>Terraform will perform the following actions:

  # google_compute_security_policy.policy will be created
  + resource &quot;google_compute_security_policy&quot; &quot;policy&quot; {
      + id   = (known after apply)
      + name = &quot;edge-policy&quot;
      ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.</pre><div class="docs-mock-kv"><div><strong>Step</strong>: tf/checkov</div><div><strong>Success</strong>: ✖️</div><div><strong>Command</strong>: <span class="docs-mock-mono">checkov --quiet --compact -f /tmp/tmp7k2m9d/checkov.plan.json</span></div></div><pre>terraform_plan scan results:

Passed checks: 0, Failed checks: 1, Skipped checks: 0

Check: CKV_GCP_73: &quot;Ensure Cloud Armor prevents message lookup in Log4j2. See CVE-2021-44228 aka log4jshell&quot;
	FAILED for resource: google_compute_security_policy.policy
	File: /checkov.plan.json:0-0</pre></div></details><hr><details><summary><strong>Feedback?</strong></summary><p>Questions? Comments? Give feedback by commenting <code>stategraph feedback &lt;your msg&gt;</code>. Your message lands directly in our inbox.</p></details></div>
</div>
<figcaption>A plan that failed the checkov scan.<br> The <code>tf/checkov</code> step lists each failed check and resource.</figcaption>
</figure>

### Approval gates

- Set `gate` on the `checkov` step to record a gate instead of failing the plan. Orchestration then blocks the apply until an authorized user approves it. See [Gatekeeper](/docs/orchestration/governance/gatekeeper).
- Set `ignore_errors: true` to report findings without blocking.

The [workflows reference](/docs/reference/orchestration/configuration/workflows) lists all keys of the step, including `extra_args`, `env`, `run_on`, and `visible_on`.

### Checkov version

To use a specific checkov release, set `CHECKOV_VERSION` before the step:

```yaml
workflows:
  - tag_query: ''
    plan:
      - type: env
        name: CHECKOV_VERSION
        cmd: ['echo', '2.3.123']
      - type: init
      - type: plan
      - type: checkov
```

Otherwise, the runner uses the version installed in its environment.

### Skip checks

Checkov reads its options from environment variables. Set `CKV_SKIP_CHECK` to a comma-separated list of check IDs to skip:

```yaml
workflows:
  - tag_query: ''
    plan:
      - type: env
        name: CKV_SKIP_CHECK
        cmd: ['echo', 'CKV_GCP_73']
      - type: init
      - type: plan
      - type: checkov
```

`CKV_CHECK` limits the scan to specific check IDs. The [checkov CLI reference](https://www.checkov.io/2.Basics/CLI%20Command%20Reference.html) lists all options.

## Next steps

- [Enable security scanning](/docs/admin/self-hosting/security-scanning): turn on scanning when self-hosted.
- [Security commands](/docs/cli/security): all commands and flags.
- [Terraform commands](/docs/cli/tf): `--security-wait` and `--skip-security`.
- [OPA](/docs/orchestration/external-tools/opa): policy checks with `conftest` and `opa`.
