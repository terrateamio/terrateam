---
title: Azure
description: Connect Stategraph Orchestration to Azure with a service principal secret or an Entra ID federated credential, then plan and apply changes.
order: 7
---

Stategraph Orchestration gets credentials for your Azure subscription from a service principal secret or from OIDC. Plans and applies run on your GitHub Actions or GitLab CI runners, so the credentials stay there. The server never holds your cloud credentials.

## Setup options

- [Static credentials](/docs/orchestration/cloud-providers/azure/static-credentials): a service principal with a client secret, stored as GitHub secrets or GitLab CI/CD variables. It gets a first plan running quickly.
- [OIDC](/docs/orchestration/cloud-providers/azure/oidc): the GitHub Actions job authenticates through an Entra ID federated credential. There is no secret to store or rotate. It is the recommended method for production.

To change to OIDC later, add an `oidc` hook to `.stategraph/config.yml` and delete the client secret.

## Next Steps

- Comment `stategraph plan` on a pull request to preview the changes, and `stategraph apply` to apply them.
- [Workflows](/docs/reference/orchestration/configuration/workflows): give each environment its own App Registration or subscription
- [Cloud credentials](/docs/orchestration/security/cloud-credentials): OIDC, static credentials, and custom credential scripts across providers
- [Configuration](/docs/orchestration/configuration): the `.stategraph/config.yml` file
