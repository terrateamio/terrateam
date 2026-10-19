---
title: Installing packages
description: Install extra packages on the Stategraph Orchestration runner, globally with a pre hook or inside one workflow, using apt-get in run steps.
order: 4
---

To add a package to the Stategraph Orchestration runner, install it with a `run` step: for every operation, or in one workflow. The runner image has a set of packages already. The same image runs on GitHub Actions and GitLab CI, so these steps work on both.

## Installing packages globally

When several workflows need a package, install it one time for every run. Commands in the `hooks.all.pre` section of `.stategraph/config.yml` run at the start of each operation, so the package is there for every workflow. This example installs `golang-go`:

```yaml
hooks:
  all:
    pre:
      - type: run
        cmd: ['apt-get', 'update']
      - type: run
        cmd: ['apt-get', '-y', 'install', 'golang-go']
```

Run `apt-get update` first. It refreshes the package lists, so you get current versions. Then `apt-get install` installs the package. The `-y` flag answers yes to each prompt.

## Installing packages in a workflow

When only some directories need a package, install it in the matching workflow. This example installs `golang-go` in the plan and apply steps of the workflow for `dir:iac/dir`, so only runs on the `iac/dir` directory install it:

```yaml
workflows:
  - tag_query: "dir:iac/dir"
    plan:
      - type: run
        cmd: ['apt-get', 'update']
      - type: run
        cmd: ['apt-get', '-y', 'install', 'golang-go']
      - type: init
      - type: plan
    apply:
      - type: run
        cmd: ['apt-get', 'update']
      - type: run
        cmd: ['apt-get', '-y', 'install', 'golang-go']
      - type: init
      - type: apply
```

## Best practices

Install only what a run needs. Fewer packages give fewer conflicts and a smaller attack surface.

## Next Steps

- [hooks reference](/docs/reference/orchestration/configuration/hooks): the `all`, `plan`, and `apply` hooks
- [workflows reference](/docs/reference/orchestration/configuration/workflows): the `run` step keys
- [Pulumi](/docs/orchestration/iac-tools/pulumi): installing a language runtime with a pre hook
