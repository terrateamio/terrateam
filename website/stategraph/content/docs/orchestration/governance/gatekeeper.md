---
title: Gatekeeper
description: Create manual approval gates in Stategraph Orchestration so authorized users can override failed security scans, policy checks, and validations.
order: 2
---


!!! note "Enterprise Edition"
    Gatekeeper is an Enterprise feature, in Stategraph Cloud and in self-hosted Enterprise deployments. The Open Source edition does not have it. See [Editions](/docs/get-started/editions).

Gatekeeper adds manual approval gates to your Stategraph Orchestration workflows. When a gated security scan, policy check, or custom validation fails, authorized users can approve the failure, and the apply continues. Use it when a person must decide if a violation is acceptable in context. Teams keep strict automated checks, and still allow legitimate exceptions.

## How Gatekeeper works

1. A workflow step with a gate fails during the plan, for example when a security scan finds issues or a policy check finds violations.
2. Orchestration records a gate for the directory and workspace of the step. It ignores the failure of the step, and the rest of the plan workflow continues.
3. When someone tries an apply, Orchestration checks every gate of the directories and workspaces in the apply.
4. If a gate is not satisfied, Orchestration stops the apply. It posts a comment with the gate token or name, the directory and workspace, who can approve the gate, and how many approvals it still needs.
5. The team reviews the failure and decides if it is acceptable.
6. An authorized user approves the gate.
7. When every gate is satisfied, the apply continues.

How a user approves a gate depends on its token:

- A gate with a token: each requested approver must approve the gate explicitly, with a pull request comment.
- A gate without a token: all requested approvers must approve the pull request in GitHub or GitLab before the apply.

To approve a gate with a token, comment:

```text
stategraph gate approve <token>
```

One comment can approve more than one token: `stategraph gate approve <token1> <token2>`.

!!! note "Force applies bypass gates"
    A force apply ([`stategraph apply-force`](/docs/reference/orchestration/commands/apply-force)) bypasses all gates. Orchestration does not check gates and does not request gate approval.

## Configuring gates

There are three ways to create gates:

- The `gate` key of the `checkov`, `conftest`, and `opa` workflow steps. Orchestration creates the gate when the step fails.
- An `on_error` entry with `type: gate` on a `run` workflow step or hook. Orchestration creates the gate when the command exits non-zero.
- The `gates` workflow step or hook. It runs a command that prints the gates to create. Use it to compute gates, for example from the plan output.

### Gate configuration options

The `gate` object, an `on_error` entry of `type: gate`, and each gate that a `gates` step prints accept these keys:

| Key | Type | Description |
|-----|------|-------------|
| `token` | String | A unique identifier of the gate, for `stategraph gate approve <token>`. |
| `name` | String | A name for the gate. It shows why the gate exists when it has no token. |
| `all_of` | List | Users, teams, or roles that must all approve the gate. |
| `any_of` | List | Users, teams, or roles from which `any_of_count` approvals are required. |
| `any_of_count` | Integer | The number of approvals required from the `any_of` list. Default is `0`: no approval from `any_of` is required. Set it to `1` or more when you use `any_of`. |

Entries in `all_of` and `any_of` use the same syntax as [access control](/docs/reference/orchestration/configuration/access-control): `user:<username>`, `team:<team-slug>`, `role:<repository-role>`, or `*`.

A gate is satisfied when every entry in `all_of` has approved, and at least `any_of_count` different approvers that match `any_of` have approved.

### Authorization patterns

Single approver:

```yaml
gate:
  token: "security-override"
  any_of: ["user:security-lead"]
  any_of_count: 1
```

Any team member:

```yaml
gate:
  token: "platform-approval"
  any_of: ["team:platform", "team:sre"]
  any_of_count: 1
```

Multiple required approvers:

```yaml
gate:
  token: "critical-override"
  all_of: ["team:security", "team:compliance"]
```

N-of-M approvals:

```yaml
gate:
  token: "cost-approval"
  any_of: ["user:cfo", "user:cto", "user:eng-director", "user:finance-lead"]
  any_of_count: 2
```

### Gating a run step

The `run` step does not accept a `gate` key. Use `on_error`. When a `run` step has a gate in `on_error`, `ignore_errors` defaults to `true` for that step, so the failed command does not fail the plan.

```yaml
workflows:
  - tag_query: ""
    plan:
      - type: init
      - type: plan
      - type: run
        cmd: ['./scripts/cost-check.sh']
        on_error:
          - type: gate
            token: "cost-threshold"
            any_of: ["team:finance", "user:budget-owner"]
            any_of_count: 1
```

### Creating gates dynamically with the gates step

The `gates` step runs a command and reads the gates from its standard output: a JSON object with a `gates` list. Each gate accepts the keys above, and `add_reviewers` (default `true`), which requests a pull request review from the `user:` and `team:` entries in `all_of` and `any_of`. The step always counts as failed, so that Orchestration records its gates. It never fails the plan.

```yaml
workflows:
  - tag_query: ""
    plan:
      - type: init
      - type: plan
      - type: gates
        cmd: ['./scripts/compute-gates.sh']
```

Example output of `./scripts/compute-gates.sh`:

```json
{
  "gates": [
    {
      "token": "database-change",
      "name": "Database schema change",
      "any_of": ["team:dba"],
      "any_of_count": 1,
      "add_reviewers": true
    }
  ]
}
```

The `gates` step accepts these keys:

| Key | Type | Description |
|-----|------|-------------|
| `cmd` | List | Command to run. Required. |
| `env` | Object | Environment variables to set for this execution. |
| `run_on` | String | When to run the step: `success`, `failure`, or `always`. Default is `success`. |

## Common use cases

!!! warning "Gates are an override mechanism"
    Configure gates with care, so that they add flexibility and do not weaken your security posture.

### Require approval from a team based on which resources were modified

A Rego policy defines `networking_team_resources_modified` when a change modifies a resource that the networking team manages. This gate requires someone from the networking team to approve the pull request before the apply:

```yaml
workflows:
  - tag_query: ""
    plan:
      - type: init
      - type: plan
      - type: opa
        fail_on: defined
        extra_args: ['-d', 'policy.rego', 'data.terraform.networking_team_resources_modified']
        gate:
          any_of: ["team:networking"]
          any_of_count: 1
```

### Security scan overrides

Let security teams approve known false positives or accepted risks. When Checkov finds issues, members of the security or platform team review the findings, and approve them if they are acceptable:

```yaml
workflows:
  - tag_query: ""
    plan:
      - type: init
      - type: plan
      - type: checkov
        gate:
          token: "checkov-override"
          any_of: ["team:security", "team:platform"]
          any_of_count: 1
```

### Policy exception handling

Let compliance teams grant exceptions to policy violations. This gate requires an approval from the compliance team, and an approval from the compliance lead or the CISO:

```yaml
workflows:
  - tag_query: "production"
    plan:
      - type: init
      - type: plan
      - type: conftest
        gate:
          token: "policy-exception"
          all_of: ["team:compliance"]
          any_of: ["user:compliance-lead", "user:ciso"]
          any_of_count: 1
```

### Cost threshold approvals

Require a finance approval when a change goes over a cost threshold. When the cost check script fails, finance team members review and approve the change:

```yaml
workflows:
  - tag_query: ""
    plan:
      - type: init
      - type: plan
      - type: run
        cmd: ['./scripts/cost-check.sh']
        on_error:
          - type: gate
            token: "cost-threshold"
            any_of: ["team:finance", "user:budget-owner"]
            any_of_count: 1
```

### Multi-stage validation

Combine several gated checks with different approval requirements:

```yaml
workflows:
  - tag_query: "production"
    plan:
      - type: init
      - type: plan

      # Security scanning with override capability
      - type: checkov
        gate:
          token: "security-scan"
          any_of: ["team:security"]
          any_of_count: 1

      # Compliance validation with stricter approval
      - type: conftest
        gate:
          token: "compliance-check"
          all_of: ["team:compliance"]
          any_of: ["user:compliance-lead"]
          any_of_count: 1

      # Custom validation with multiple approvers required
      - type: run
        cmd: ['./scripts/validate-production.sh']
        on_error:
          - type: gate
            token: "prod-validation"
            any_of: ["team:platform", "team:sre", "team:devops"]
            any_of_count: 2
```

## Next steps

- [gate approve command](/docs/reference/orchestration/commands/gate-approve) for the pull request comment that approves a gate
- [workflows reference](/docs/reference/orchestration/configuration/workflows) for the `gate`, `on_error`, and `gates` step keys
- [hooks reference](/docs/reference/orchestration/configuration/hooks) for gates in hooks
- [Role-Based Access Control](/docs/orchestration/governance/rbac) for who can plan, apply, and override
