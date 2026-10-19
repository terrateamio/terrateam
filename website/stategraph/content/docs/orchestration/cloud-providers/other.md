---
title: Other providers
description: Give Stategraph Orchestration credentials for any Terraform provider by storing its access token as a repository secret or CI/CD variable.
order: 10
---

Stategraph Orchestration works with any cloud or service that has a Terraform provider, not only AWS, GCP, and Azure: you store the access token of the provider as a GitHub secret or a GitLab CI/CD variable. Most providers read the token from an environment variable.

Orchestration runs Terraform on your GitHub Actions or GitLab CI runners, so the provider needs the same credentials there as on your workstation. Without them, it cannot read or change resources. The runner gets GitHub secrets and GitLab CI/CD variables as environment variables. See [Variables](/docs/orchestration/configuration/variables).

Most providers are on the [Terraform Registry](https://registry.terraform.io/). Authentication is different for each provider: check its documentation for the variable names and token scopes that it requires.

## Typical setup

1. Create a user, role, or service account on the provider, with the permissions that Orchestration needs.
2. Generate an access token for it.
3. Store the token as a repository secret (GitHub) or a masked CI/CD variable (GitLab), under the environment variable name that the provider expects.

## Example: Fly.io

The `fly` provider reads its token from the `provider` block or from the `FLY_API_TOKEN` environment variable.

```hcl
provider "fly" {
  # Do not do this. Set the FLY_API_TOKEN environment variable instead.
  flytoken = "abc123"
}
```

Use the environment variable. Everyone with read access to the repository can see a token in Git, and it stays in the history after you remove it.

### Create the token

Choose the Fly.io user for Orchestration, and create an access token for it:

```bash
export FLY_API_TOKEN=$(fly auth token)
```

Store the token for your VCS, as below. On the next `stategraph plan` or `stategraph apply`, the runner gets `FLY_API_TOKEN` as an environment variable, and the provider authenticates with it.

### GitHub

Store the token as the `FLY_API_TOKEN` secret with the [GitHub CLI](https://cli.github.com/):

```bash
export REPO="<OWNER/REPO>"

gh secret --repo "$REPO" set FLY_API_TOKEN --body "$FLY_API_TOKEN"
```

### GitLab

1. Open your GitLab project and go to **Settings**, then **CI/CD**, then **Variables**.
2. Click **Add variable**, enter the **Key** `FLY_API_TOKEN`, and paste the token as the **Value**.
3. Mark the variable as masked, leave **Protect variable** cleared, then click **Add variable**.

GitLab passes protected variables only to pipelines on protected branches. Orchestration runs plans on the merge request's source branch, so those runs do not get a protected variable.

## Next Steps

- [Variables](/docs/orchestration/configuration/variables): secrets, CI/CD variables, and `.tfvars` files
- [Cloud credentials](/docs/orchestration/security/cloud-credentials): OIDC, static credentials, and custom credential scripts
- [Configuration](/docs/orchestration/configuration): the `.stategraph/config.yml` file
