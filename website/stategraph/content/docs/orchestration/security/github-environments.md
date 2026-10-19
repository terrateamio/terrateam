---
title: GitHub Environments
description: Bind Stategraph Orchestration workflows to GitHub Environments so that each environment's secrets, variables, and protection rules apply to its runs.
order: 4
---


Stategraph Orchestration can run a workflow in a [GitHub Environment](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment). The environment's secrets and variables are then available to that workflow and to no other, and the environment's protection rules apply to the run.

A GitHub Environment is a GitHub Actions feature: a named deployment target in a repository, such as `production`, `staging`, or `qa`. Each environment has its own secrets, variables, and protection rules, such as required reviewers or a branch restriction.

## Configure an environment

Set the `environment` key on a workflow in `.stategraph/config.yml`:

```yaml
workflows:
  - tag_query: production
    environment: production
```

This workflow runs in the `production` GitHub Environment, with the secrets and variables of that environment.

To bind several workflows to several environments:

```yaml
workflows:
  - tag_query: staging
    environment: staging
  - tag_query: qa
    environment: qa
```

Each workflow runs in the environment that its `environment` key names. See the [workflows reference](/docs/reference/orchestration/configuration/workflows).

## Best practices

- Name environments after their purpose: `production`, `staging`, `qa`.
- Store API keys, passwords, and certificates as secrets in their environment, not as repository secrets.
- Add protection rules, such as required reviewers or required status checks, to critical environments.
- Pair environments with [access control](/docs/reference/orchestration/configuration/access-control), so that only the right people can start runs in them. See [Security best practices](/docs/orchestration/security).

## Next steps

- [Cloud credentials](/docs/orchestration/security/cloud-credentials): OIDC role ARNs and other secrets referenced from the environment.
- [Hardening AWS OIDC](/docs/orchestration/security/hardening-aws-oidc): restrict which runs can assume a role.
