---
title: Azure static credentials
description: Create an Azure service principal with a client secret and store its values as GitHub secrets or GitLab CI/CD variables for Orchestration.
order: 9
---

With static credentials, Stategraph Orchestration reaches Azure with a dedicated service principal and its client secret. It gets a first plan running quickly.

!!! warning "Consider OIDC"
    Static credentials are long-lived secrets in your repository settings. For production, [OIDC](/docs/orchestration/cloud-providers/azure/oidc) authenticates with short-lived tokens and nothing to rotate.

Setup has two steps:

1. Create the service principal with the Azure CLI.
2. Store its values as GitHub secrets with the GitHub CLI, or as GitLab CI/CD variables in the GitLab UI.

The runner gets the values as environment variables, and the AzureRM provider reads them there. Keep hooks and workflow steps from printing them. See [Variables](/docs/orchestration/configuration/variables).

## Prerequisites

- The [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/)
- The [GitHub CLI](https://cli.github.com/), if you store the credentials on GitHub

## Create a service principal

1. Log in to the Azure CLI:

```bash
az login
```

2. List your subscriptions. The `id` field is your subscription ID:

```bash
az account list
```

Output:

```json
[
  {
    "cloudName": "AzureCloud",
    "id": "00000000-0000-0000-0000-000000000000",
    "isDefault": true,
    "name": "PAYG Subscription",
    "state": "Enabled",
    "tenantId": "00000000-0000-0000-0000-000000000000",
    "user": {
      "name": "user@example.com",
      "type": "user"
    }
  }
]
```

3. Export the subscription ID and select it:

```bash
export SUBSCRIPTION_ID="<subscription-id>"
az account set --subscription "$SUBSCRIPTION_ID"
```

4. Create the service principal with a role on the subscription:

```bash
az ad sp create-for-rbac --role="Contributor" \
--scopes="/subscriptions/$SUBSCRIPTION_ID"
```

`Contributor` is an Azure built-in role. It grants full access to manage resources, but it cannot assign roles in Azure RBAC, manage assignments in Azure Blueprints, or share image galleries. Use the role that fits your organization.

Output:

```json
{
  "appId": "00000000-0000-0000-0000-000000000000",
  "displayName": "azure-cli-2017-06-05-10-41-15",
  "name": "http://azure-cli-2017-06-05-10-41-15",
  "password": "0000-0000-0000-0000-000000000000",
  "tenant": "00000000-0000-0000-0000-000000000000"
}
```

The AzureRM provider uses other names for these values. Record the mapping for the next section:

- `appId` maps to `ARM_CLIENT_ID`
- `password` maps to `ARM_CLIENT_SECRET`
- `tenant` maps to `ARM_TENANT_ID`

## Store the credentials

Store the four values for your VCS. Then Orchestration can run `stategraph plan` and `stategraph apply` against your Azure resources.

### GitHub

1. Export your `organization/repo` name:

```bash
export REPO="<OWNER/REPO>"
```

2. Create the subscription ID secret:

```bash
gh secret --repo "$REPO" set ARM_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID"
```

3. Create the client ID secret, and paste the `appId` value when the CLI asks for it:

```bash
gh secret --repo "$REPO" set ARM_CLIENT_ID
```

4. Create the client secret, and paste the `password` value:

```bash
gh secret --repo "$REPO" set ARM_CLIENT_SECRET
```

5. Create the tenant ID secret, and paste the `tenant` value:

```bash
gh secret --repo "$REPO" set ARM_TENANT_ID
```

### GitLab

1. Open your GitLab project and go to **Settings**, then **CI/CD**, then **Variables**.
2. Click **Add variable**, enter the **Key** `ARM_SUBSCRIPTION_ID`, and paste your subscription ID as the **Value**. Leave **Protect variable** cleared, then click **Add variable**.
3. Do the same for `ARM_CLIENT_ID` with the `appId` value, and for `ARM_TENANT_ID` with the `tenant` value.
4. Do the same for `ARM_CLIENT_SECRET` with the `password` value, and mark this variable as masked.

GitLab passes protected variables only to pipelines on protected branches. Orchestration runs plans on the merge request's source branch, so those runs do not get a protected variable. To share the credentials across projects, add the variables to the GitLab group.

## Next Steps

- [Configuration](/docs/orchestration/configuration): customize workflows in `.stategraph/config.yml`
- [Azure OIDC](/docs/orchestration/cloud-providers/azure/oidc): migrate to keyless authentication
- [Cloud credentials](/docs/orchestration/security/cloud-credentials): credential patterns across providers
