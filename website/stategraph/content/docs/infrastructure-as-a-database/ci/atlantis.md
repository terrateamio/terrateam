---
title: Atlantis
description: Keep Atlantis for pull request automation, and run plans and applies through Stategraph with two run steps.
order: 4
---

Two `run` steps in an Atlantis custom workflow send plans and applies through the `stategraph` CLI, and Stategraph holds the state. Atlantis still runs your pull request automation.

## Before you begin

- The `stategraph` binary and OpenTofu on the Atlantis server's `PATH` before the first plan. Atlantis has no per-run install hook, so use a derived image of your Atlantis base image, or a custom image with both.
- A Stategraph server that the Atlantis server can reach, with `STATEGRAPH_API_BASE`, `STATEGRAPH_API_KEY`, and `STATEGRAPH_TENANT_ID` in the Atlantis server's environment.
- Your state imported once, with `stategraph.json` committed. See [Import your Terraform state](/docs/get-started/quickstart/import-state).

## Define the workflow

On the server, in `repos.yaml`:

```yaml
repos:
  - id: github.com/acme/infra
    workflow: stategraph

workflows:
  stategraph:
    plan:
      steps:
        - run: stategraph plan --out $PLANFILE
    apply:
      steps:
        - run: stategraph apply $PLANFILE
```

The `id` is the repository's full name with the host, for example `gitlab.com/acme/infra` for a GitLab project.

Or in the repository, in `atlantis.yaml`, if your server sets `allowed_overrides: [workflow]` and `allow_custom_workflows: true`:

```yaml
version: 3
projects:
  - dir: infra
    workflow: stategraph
workflows:
  stategraph:
    plan:
      steps:
        - run: stategraph plan --out $PLANFILE
    apply:
      steps:
        - run: stategraph apply $PLANFILE
```

`stategraph plan --out` writes the plan to `$PLANFILE`, where Atlantis expects it. The apply step commits exactly that reviewed plan. Atlantis posts the plan output, the Stategraph diff, to the pull request.

## What changes

- Atlantis still handles `atlantis plan` and `atlantis apply` comments, posts results on the pull request, and tracks which pull request holds which project.
- Refresh, plan, and apply cover only the subgraph that your change touches.
- The global state lock is gone. Pull requests that touch different resources do not wait for each other's state lock. A real overlap fails per resource at commit, with the conflicting transaction ID.
- Atlantis working-directory locks stay per project. They stop two pull requests from planning the same project directory at once, for workspace hygiene, not for state.

## Limitations

The CLI does not support destroy yet. Keep `atlantis destroy`-style workflows on your existing path, or run destroys locally.

## Next Steps

- [Setup](/docs/infrastructure-as-a-database/setup): state import and CLI configuration.
- [Transactions](/docs/infrastructure-as-a-database/transactions): what an apply commits.
- [GitHub Actions](/docs/infrastructure-as-a-database/ci/github-actions): the plain-CI variant.
- [GitLab CI](/docs/infrastructure-as-a-database/ci/gitlab-ci): the plain-CI variant.
- [Workflows](/docs/orchestration/workflows): Stategraph Orchestration, for comment-driven pull request automation.
