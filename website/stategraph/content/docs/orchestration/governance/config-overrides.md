---
title: Feature Branch Configuration Overrides
description: Control which .stategraph/config.yml keys must come from the default branch and which feature branches may override with default_branch_overrides.
order: 5
---


`default_branch_overrides` lists the configuration keys that Stategraph Orchestration reads from the default branch (usually `main` or `master`), not from the feature branch. A user cannot change these keys in a feature branch, so they cannot bypass security controls with an edit to the configuration in their branch.

## Default configuration

By default, the list holds three security-critical keys:

```yaml
default_branch_overrides:
  - access_control
  - apply_requirements
  - destination_branches
```

- `access_control`: who can run Orchestration commands
- `apply_requirements`: the approvals and checks that an apply needs
- `destination_branches`: the branches that changes can merge into

Orchestration reads all other configuration, such as workflows and hooks, from the feature branch. You can add any top-level key to the list, to read it from the default branch too. Orchestration always reads `default_branch_overrides` itself from the default branch, so a feature branch cannot remove a key from the list.

## Allowing feature branch overrides

To let feature branches change a key, remove it from the list:

```yaml
# Allow apply_requirements to be tested in feature branches
default_branch_overrides:
  - access_control
  - destination_branches
```

Now you can change and test `apply_requirements` in feature branches. `access_control` and `destination_branches` still come from the default branch.

## Security considerations

!!! warning "Removing keys weakens security"
    Each key that you remove from `default_branch_overrides` is a key that a feature branch can change. Choose these keys with care.

When you remove a key from the list:

- `access_control`: any user can grant themselves permissions in their feature branch. Unauthorized users could run apply commands and bypass security boundaries.
- `apply_requirements`: users could bypass approval requirements in their branches, disable critical checks, and violate compliance requirements.
- `destination_branches`: users could change which target branches allow Terraform operations.

## Next steps

- [default_branch_overrides reference](/docs/reference/orchestration/configuration/default-branch-overrides)
- [Centralized Configuration](/docs/orchestration/governance/centralized-config) for organization-wide defaults and overrides
- [Role-Based Access Control](/docs/orchestration/governance/rbac)
