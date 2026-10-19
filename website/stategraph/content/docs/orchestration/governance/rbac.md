---
title: Role-Based Access Control
description: Control who can plan, apply, and override in Stategraph Orchestration with access control policies by user, team, repository role, and tag query.
order: 1
---


!!! note "Enterprise Edition"
    Role-based access control is an Enterprise feature, in Stategraph Cloud and in self-hosted Enterprise deployments. The Open Source edition does not permit `access_control.enabled: true`: Orchestration rejects the configuration and posts a comment on the pull request. See [Editions](/docs/get-started/editions).

Role-based access control sets who can plan, apply, and override the apply requirements in Stategraph Orchestration. The [access control](/docs/reference/orchestration/configuration/access-control) configuration gives each capability to users, teams, or repository roles, per tag query. Only authorized users can change your infrastructure, which reduces the risk of accidental or unauthorized changes.

## Access control

### Enabling access control

Add this to `.stategraph/config.yml`:

```yaml
access_control:
  enabled: true
```

### Configuring access control policies

!!! warning "Policy order matters"
    List `policies` from the most specific `tag_query` to the most general. Orchestration uses the first policy in the list that matches. `tag_query: ''` is the most general, matches everything, and should always be last.

```yaml
access_control:
  enabled: true
  apply_require_all_dirspace_access: true
  plan_require_all_dirspace_access: false
  terrateam_config_update: ['*']
  unlock: ['*']
  policies:
    - tag_query: ''
      apply: ['role:maintain']
      apply_autoapprove: ['user:jane-doe']
      apply_force: ['team:sre']
      apply_with_superapproval: ['role:write']
      plan: ['*']
      superapproval: ['user:john-doe']
```

In this example:

- `apply` goes to users with the `maintain` role in the repository.
- `apply_autoapprove` goes to the user `jane-doe`.
- `apply_force` goes to members of the `sre` team.
- `apply_with_superapproval` goes to users with the `write` role in the repository, but only after a user with the `superapproval` capability approves the pull request.
- `plan` goes to all users (`*`).
- `superapproval` goes to the user `john-doe`.

### Users, teams, and roles on GitHub and GitLab

Rules use the same syntax on both providers. What each rule matches depends on the provider:

| Rule | GitHub | GitLab |
| --- | --- | --- |
| `user:<name>` | GitHub username | GitLab username |
| `team:<name>` | Member of the organization's team with that slug | Direct member of the group with that path, for example `team:sre` or `team:acme/sre` for a subgroup |
| `role:<role>` | Repository role | Project role, mapped as below |

A `role:` rule matches that role and every stronger one, in the order `admin`, `maintain`, `write`, `triage`, `read`. GitLab project roles map to these roles:

- Guest, Planner, and Reporter count as `read`.
- Developer counts as `write`.
- Maintainer and Owner count as `maintain`.

No standard GitLab project role counts as `triage` or `admin`. So on GitLab, `role:triage` matches Developer and above, and `role:maintain` is the rule for Maintainers and Owners.

## Plan permissions

The `plan` capability sets who can run plan operations. By default, all users (`*`) have it, so anyone can generate and review plans for proposed changes. To give it only to users with the `write` role:

```yaml
access_control:
  enabled: true
  policies:
    - tag_query: ''
      plan: ['role:write']
```

## Apply permissions

The `apply` capability sets who can run apply operations. By default, all users (`*`) have it, so anyone can apply changes. To give it to one team:

```yaml
access_control:
  enabled: true
  policies:
    - tag_query: ''
      apply: ['team:devops']
```

### Apply requirements

An apply also needs its [apply requirements](/docs/reference/orchestration/configuration/apply-requirements), so that changes are reviewed and approved before they are applied. By default:

- The pull request must not have merge conflicts.
- All status checks of the pull request must pass.

Configure them in `apply_requirements.checks`:

```yaml
apply_requirements:
  checks:
    - tag_query: ''
      approved:
        enabled: true
        any_of_count: 2
      merge_conflicts:
        enabled: true
      status_checks:
        enabled: true
        ignore_matching:
          - "ci/.*"
```

In this example:

- The pull request must have at least 2 approvals.
- The pull request must not have merge conflicts.
- All status checks of the pull request must pass, except the checks that match the pattern `ci/.*`.

On GitLab, approvals come from the approvals and reviewers of the merge request, and status checks are the commit statuses on its latest commit.

### Apply overrides

To override the apply requirements, Orchestration has two pull request comment commands:

- [`stategraph apply-force`](/docs/reference/orchestration/commands/apply-force): users with the `apply_force` capability bypass all apply requirements and force an apply.
- [`stategraph apply-autoapprove`](/docs/reference/orchestration/commands/apply-autoapprove): users with the `apply_autoapprove` capability approve and apply changes with no other approvals.

!!! danger "Warning"
    Give override capabilities only to trusted users who understand the risks of bypassing apply requirements.

## Combining plan and apply permissions

Combine plan and apply permissions to match the roles and responsibilities in your organization. For example, give plan permissions to a large group that proposes and reviews changes, and apply permissions to a small group of trusted users who approve and execute them:

```yaml
access_control:
  enabled: true
  policies:
    - tag_query: ''
      plan: ['role:write']
      apply: ['role:maintain']
      apply_autoapprove: ['user:jane-doe']
      apply_force: ['team:sre']
```

In this configuration:

- Users with the `write` role can run plan operations and propose changes.
- Users with the `maintain` role can run apply operations and approve changes.
- The user `jane-doe` can use `stategraph apply-autoapprove` to approve and apply changes.
- Members of the `sre` team can use `stategraph apply-force` to bypass apply requirements and force an apply.

## Best practices

- Follow the principle of least privilege. Give users only the permissions that they need for their tasks.
- Use `apply_require_all_dirspace_access` and `plan_require_all_dirspace_access` to control whether users need access to every targeted directory and workspace ([dirspace](/docs/get-started/core-concepts#repository-directory-and-workspace)) to run an apply or a plan.

## Next steps

- [access_control reference](/docs/reference/orchestration/configuration/access-control) for every key and the rule syntax
- [apply_requirements reference](/docs/reference/orchestration/configuration/apply-requirements) for approval, merge conflict, and status check rules
- [CODEOWNERS](/docs/orchestration/configuration/codeowners) to enforce code owner reviews before apply
- [Gatekeeper](/docs/orchestration/governance/gatekeeper) for manual approval gates on failed checks
