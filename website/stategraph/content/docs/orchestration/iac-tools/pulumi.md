---
title: Pulumi
description: Run Pulumi previews and updates through Stategraph Orchestration pull requests with the pulumi engine, runtime hooks, and stack directories.
order: 4
---

Stategraph Orchestration runs Pulumi previews and updates from pull requests, as it runs Terraform plans and applies. Orchestration comments the preview on the pull request. After review and approval, comment `stategraph apply` to run the update, and Orchestration comments its output. [Pulumi](https://pulumi.com) is an open-source infrastructure as code tool that defines cloud infrastructure in general-purpose programming languages.

!!! note "Status"
    The Pulumi engine is in active development.

Orchestration adds these controls to Pulumi:

- Apply requirements: `pulumi up` runs only after the approvals and status checks that you require.
- Permissions: you control which users run which operations on which stacks.
- Safety: only one `pulumi up` runs at a time for a stack, so concurrent edits cannot collide.
- Preview invalidation: after one person runs an update, everyone else must preview again before they apply.

## Enable Pulumi

The `engine` key sets the tool that Orchestration runs: Terraform, OpenTofu, the `stategraph` CLI, Terragrunt, Pulumi, CDKTF, or a custom command. For Pulumi, set it in `.stategraph/config.yml`:

```yaml
engine:
  name: pulumi
```

### Directory configuration

Put your Pulumi stacks under a directory, and set the files that start a run. Each key under `stacks` is the name of a Pulumi stack. For a Pulumi program in `code` that uses the YAML runtime:

```yaml
dirs:
  code:
    when_modified:
      file_patterns:
        - '${DIR}/**/*.yaml'
    stacks:
      dev: {}
```

For the TypeScript runtime:

```yaml
dirs:
  code:
    when_modified:
      file_patterns:
        - '${DIR}/**/*.ts'
    stacks:
      dev: {}
```

### Hooks for language runtimes

Pulumi programs need their language runtime on the runner. Install it with a pre hook, which runs before each operation. This example installs Node.js for a TypeScript program. See [Installing packages](/docs/orchestration/external-tools/installing-packages).

```yaml
hooks:
  all:
    pre:
      - type: run
        cmd: ['apt-get', 'update']
      - type: run
        cmd: ['apt-get', '-y', 'install', 'nodejs', 'npm']
```

To help improve runtime setup, tell [Support](/docs/support) which runtimes you use.

### Hooks for configuration

To run a stack with local state and an empty passphrase, set the passphrase with an `env` hook:

```yaml
hooks:
  all:
    pre:
      - type: env
        name: PULUMI_CONFIG_PASSPHRASE
        cmd: ['echo', '']
```

## Log in

Pulumi must log in before it runs. The `init` workflow step runs `pulumi login`. Give the login location in `extra_args`:

```yaml
workflows:
  - tag_query: ''
    plan:
      - type: init
        extra_args: ['file://${TERRATEAM_ROOT}/pulumi']
      - type: plan
    apply:
      - type: init
        extra_args: ['file://${TERRATEAM_ROOT}/pulumi']
      - type: apply
```

## Cost estimation

Turn off cost estimation when you use Pulumi:

```yaml
cost_estimation:
  enabled: false
```

## Next Steps

- [hooks reference](/docs/reference/orchestration/configuration/hooks): pre and post hooks for every operation
- [workflows reference](/docs/reference/orchestration/configuration/workflows): the `init`, `plan`, and `apply` steps and their keys
- [Apply requirements](/docs/reference/orchestration/configuration/apply-requirements): gate updates on approvals and checks
