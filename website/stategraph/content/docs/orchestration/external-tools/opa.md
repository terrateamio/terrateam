---
title: Policy enforcement with OPA
description: Enforce Rego policies on every Stategraph Orchestration plan with the conftest and opa workflow steps, custom policy directories, and approval gates.
order: 1
---

Stategraph Orchestration checks each Terraform plan against your policies before it can be applied, so your configurations stay in your organization's standards and compliance requirements. You write the policies in Rego. A workflow step runs them: the `conftest` step runs Conftest, and the `opa` step runs Open Policy Agent (OPA).

- [Open Policy Agent (OPA)](https://www.openpolicyagent.org/) is an open-source, general-purpose policy engine. It has Rego, a declarative policy language, and a runtime that evaluates policies against structured data such as JSON or YAML.
- [Conftest](https://www.conftest.dev/) is a command-line tool that tests structured configuration data, such as Terraform plans, Kubernetes manifests, or Serverless configurations, with Rego policies.

## Configuring policy enforcement

Add a `conftest` step to a workflow in `.stategraph/config.yml`:

```yaml
workflows:
  - tag_query: ''
    plan:
      - type: init
      - type: plan
      - type: conftest
```

- The `init` and `plan` steps make the Terraform plan as usual.
- The `conftest` step converts the plan to JSON and runs Conftest on it with the policies in the policy directory. You do not script the Conftest command yourself.
- When the plan violates a policy, Conftest exits non-zero and the plan operation fails.
- The plan results on the pull request include the Conftest output, with each violation.
- When the plan passes every check, the plan operation succeeds, and you review and apply the plan as usual.

To let authorized users approve a policy violation, and not fail the plan, add a `gate` to the `conftest` or `opa` step. See [Gatekeeper](/docs/orchestration/governance/gatekeeper).

### Running OPA directly

The `opa` step runs `opa eval` on the JSON form of the plan, without Conftest. Give the policy and the query in `extra_args`. `fail_on` sets which query result fails the step: `defined`, or `undefined` (the default).

```yaml
workflows:
  - tag_query: ''
    plan:
      - type: init
      - type: plan
      - type: opa
        fail_on: defined
        extra_args: ['-d', 'policy/main.rego', 'data.main.violation']
```

Here the step fails when `data.main.violation` has a defined value. So `violation` must be a rule that is defined only when the plan violates the policy. A partial set rule such as `deny` is always defined, even when it is empty. For all keys, see the [workflows reference](/docs/reference/orchestration/configuration/workflows#opa).

## Defining policies with Rego

Conftest policies use [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/). This policy denies the creation of a `null_resource`:

```rego
package main
resource_types = {"null_resource"}
resources[resource_type] = all {
    some resource_type
    resource_types[resource_type]
    all := [name |
        name:= input.resource_changes[_]
        name.type == resource_type
    ]
}
num_creates[resource_type] = num {
    some resource_type
    resource_types[resource_type]
    all := resources[resource_type]
    creates := [res |  res:= all[_]; res.change.actions[_] == "create"]
    num := count(creates)
}
deny[msg] {
    num_resources := num_creates["null_resource"]
    num_resources > 0
    msg := "Resource 'null_resource' detected in Terraform plan file. Denied."
}
```

The `deny` rule gives an error message each time the plan creates a `null_resource`.

<figure class="docs-figure" data-vcs="github">
<div class="docs-mock">
<div class="docs-mock-bar"><span class="docs-mock-avatar"><img src="/assets/logo-symbol.svg" alt=""></span><span class="vcs-github docs-mock-author">Stategraph GitHub App</span><span class="vcs-github docs-mock-badge">bot</span><span class="vcs-gitlab docs-mock-author">Access token user</span><span>commented</span><span class="docs-vcs-switch" role="group" aria-label="Provider"><button type="button" data-vcs-set="github" aria-pressed="true">GitHub</button><button type="button" data-vcs-set="gitlab" aria-pressed="false">GitLab</button></span></div><div class="docs-mock-body"><div class="docs-mock-h">Plans ✖️</div><p>Running plans <strong>FAILED</strong>. See <strong>Stategraph Plan Output</strong>.</p><p>After resolving the issue, run <code>stategraph plan</code> to execute the plan operation again.</p><div class="docs-mock-h">Stategraph Plan Output ✖️</div><details open><summary>Expand for plan output details</summary><div class="docs-mock-details"><div class="docs-mock-h small">dev | default | ✖️</div><div class="docs-mock-kv"><div><strong>Dir</strong>: dev</div><div><strong>Workspace</strong>: default</div><div><strong>Success</strong>: ✖️</div></div><div class="docs-mock-kv"><div><strong>Step</strong>: tf/plan</div><div><strong>Success</strong>: 👍</div></div><pre>Terraform will perform the following actions:

  # null_resource.foobar will be created
  + resource &quot;null_resource&quot; &quot;foobar&quot; {
      + id = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.</pre><div class="docs-mock-kv"><div><strong>Step</strong>: tf/conftest</div><div><strong>Success</strong>: ✖️</div><div><strong>Command</strong>: <span class="docs-mock-mono">conftest test --ignore .git /tmp/tmpq8n2x1/conftest.plan.json</span></div></div><pre>FAIL - /tmp/tmpq8n2x1/conftest.plan.json - main - Resource &#x27;null_resource&#x27; detected in Terraform plan file. Denied.

3 tests, 2 passed, 0 warnings, 1 failure, 0 exceptions</pre></div></details><hr><details><summary><strong>Feedback?</strong></summary><p>Questions? Comments? Give feedback by commenting <code>stategraph feedback &lt;your msg&gt;</code>. Your message lands directly in our inbox.</p></details></div>
</div>
<figcaption>A plan that failed the Conftest policy above.<br> The <code>tf/conftest</code> step shows each violation.</figcaption>
</figure>

## Policy directory structure

By default, Conftest looks for Rego files in the `policy` directory of the directory that it checks. When a pull request changes `foo/bar/main.tf`, Conftest looks for policies in `foo/bar/policy/`:

```
foo
└── bar
    ├── main.tf
    └── policy
        └── main.rego
```

To use a different directory, set `CONFTEST_POLICY`. See [Specifying a custom policy directory](#specifying-a-custom-policy-directory).

## Customizing Conftest options

Conftest reads its options from environment variables. For the full list, see the [Conftest documentation](https://www.conftest.dev/options/).

### Specifying the Conftest version

Set `CONFTEST_VERSION` to run a specific Conftest release. The runner installs that version before the step runs. Without it, the runner uses the version in its image. A fixed version keeps behavior the same across the team, and lets you try a new version before you adopt it everywhere.

```yaml
workflows:
  - tag_query: ''
    plan:
      - type: env
        name: CONFTEST_VERSION
        cmd: ['echo', '0.40.0']
      - type: init
      - type: plan
      - type: conftest
```

### Specifying a custom policy directory

Set `CONFTEST_POLICY` in the workflow:

```yaml
workflows:
  - tag_query: 'dir:aws/us-east-1/production/iam'
    plan:
      - type: init
      - type: plan
      - type: env
        name: CONFTEST_POLICY
        cmd: ['echo', '$TERRATEAM_ROOT/aws/policies/iam/']
      - type: conftest
```

The `env` step sets `CONFTEST_POLICY` to `aws/policies/iam/`, relative to the repository root (`$TERRATEAM_ROOT`). When a pull request changes `aws/us-east-1/production/iam/main.tf`, the `conftest` step uses the policies in `aws/policies/iam/`.

## Best practices

- Write clear, short policies that match your organization's standards and compliance requirements.
- Write error messages that tell the author why the plan failed and how to fix it.
- Put policies in a directory structure that mirrors your infrastructure, so they are easy to find and maintain.

## Next Steps

- [workflows reference](/docs/reference/orchestration/configuration/workflows): the `conftest` and `opa` step keys
- [Gatekeeper](/docs/orchestration/governance/gatekeeper): approval gates for policy violations
- [Security scanning](/docs/infrastructure-as-a-database/security): Checkov scanning on every plan
