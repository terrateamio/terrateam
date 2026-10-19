---
title: default_branch_overrides
description: Reference for the default_branch_overrides key in .stategraph/config.yml. Choose which root keys are read from the default branch.
order: 7
---


`default_branch_overrides` lists the root keys of the configuration that Stategraph Orchestration reads from the default branch. A pull request branch cannot change these keys. Only root keys are valid.

## Default Configuration

```yaml
default_branch_overrides:
  - access_control
  - apply_requirements
  - destination_branches
```

Your list replaces the default list, so include every key that must come from the default branch. A key that is not in the list can come from any feature branch, so take care when you remove a key that controls security.

## Examples

### Allow Apply Requirements to Be Specified in a Feature Branch

```yaml
default_branch_overrides:
  - access_control
  - destination_branches
```

## Related

- [Feature branch config overrides](/docs/orchestration/governance/config-overrides)
- [access_control](/docs/reference/orchestration/configuration/access-control)
- [apply_requirements](/docs/reference/orchestration/configuration/apply-requirements)
- [destination_branches](/docs/reference/orchestration/configuration/destination-branches)
