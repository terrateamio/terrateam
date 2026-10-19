---
title: AWS
description: Connect Stategraph Orchestration to AWS with static IAM access keys or OpenID Connect, then run plan and apply against your AWS account.
order: 1
---

Stategraph Orchestration gets credentials for your AWS account from static access keys or from OIDC. Plans and applies run on your GitHub Actions or GitLab CI runners, so the credentials stay there. The server never holds your cloud credentials.

## Setup options

- [Static credentials](/docs/orchestration/cloud-providers/aws/static-credentials): an IAM user with access keys, stored as GitHub secrets or GitLab CI/CD variables. It gets a first plan running quickly.
- [OIDC](/docs/orchestration/cloud-providers/aws/oidc): the GitHub Actions job assumes an IAM role through the GitHub OpenID Connect provider. There are no long-lived keys to store or rotate. It is the recommended method for production.

To change to OIDC later, add an `oidc` hook to `.stategraph/config.yml` and delete the access keys.

## Next Steps

- Comment `stategraph plan` on a pull request to preview the changes, and `stategraph apply` to apply them.
- [Workflows](/docs/reference/orchestration/configuration/workflows): give each environment its own role or credentials
- [Cloud credentials](/docs/orchestration/security/cloud-credentials): OIDC, static credentials, and custom credential scripts across providers
- [Hardening AWS OIDC](/docs/orchestration/security/hardening-aws-oidc): tighten the trust policy before production use
- [Configuration](/docs/orchestration/configuration): the `.stategraph/config.yml` file
