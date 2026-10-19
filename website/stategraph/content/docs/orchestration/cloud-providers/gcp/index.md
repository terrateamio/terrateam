---
title: GCP
description: Connect Stategraph Orchestration to Google Cloud with a service account key or Workload Identity Federation, then plan and apply against your project.
order: 4
---

Stategraph Orchestration gets credentials for your Google Cloud project from a service account key or from OIDC. Plans and applies run on your GitHub Actions or GitLab CI runners, so the credentials stay there. The server never holds your cloud credentials.

## Setup options

- [Static credentials](/docs/orchestration/cloud-providers/gcp/static-credentials): a service account key, stored as a GitHub secret or GitLab CI/CD variable. It gets a first plan running quickly.
- [OIDC](/docs/orchestration/cloud-providers/gcp/oidc): the GitHub Actions job impersonates a service account through Workload Identity Federation. There is no key file to store or rotate. It is the recommended method for production.

To change to OIDC later, add an `oidc` hook to `.stategraph/config.yml` and delete the key.

## Next Steps

- Comment `stategraph plan` on a pull request to preview the changes, and `stategraph apply` to apply them.
- [Workflows](/docs/reference/orchestration/configuration/workflows): give each environment its own service account
- [Cloud credentials](/docs/orchestration/security/cloud-credentials): OIDC, static credentials, and custom credential scripts across providers
- [GitHub Environments](/docs/orchestration/security/github-environments): let Google verify which GitHub Actions environment a run came from
- [Configuration](/docs/orchestration/configuration): the `.stategraph/config.yml` file
