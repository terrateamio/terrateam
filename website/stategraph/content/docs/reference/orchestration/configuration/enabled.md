---
title: enabled
description: Reference for the top-level enabled key in .stategraph/config.yml. Turn Stategraph Orchestration on or off for a whole repository.
order: 12
---


`enabled` turns Stategraph Orchestration on or off for a repository. Set it at the top level of `.stategraph/config.yml`.

## Default Configuration

```yaml
enabled: true
```

## Keys

| Key | Type | Description |
| --- | --- | --- |
| `enabled` | boolean | `false` turns Orchestration off for this repository. Default is `true`. |

When a repository is disabled:

- Orchestration ignores all events from the repository, including pull request creation, updates, and merges.
- No plans or applies run, and Orchestration adds no comments to pull requests.
- Existing Terraform state and the resources that Orchestration created do not change. Orchestration only stops making changes to the infrastructure.

Disable a repository to stop Orchestration for a period, for example during maintenance or troubleshooting.

## Examples

### Enabling a Repository

```yaml
enabled: true
```

### Disabling a Repository

```yaml
enabled: false
```

## Related

- [Configuration overview](/docs/orchestration/configuration)
- [version](/docs/reference/orchestration/configuration/version)
