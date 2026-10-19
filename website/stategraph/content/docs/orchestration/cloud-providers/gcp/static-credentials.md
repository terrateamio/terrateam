---
title: GCP static credentials
description: Create a Google Cloud service account key and store it as a GitHub secret or GitLab CI/CD variable so Stategraph Orchestration can reach GCP.
order: 6
---

With static credentials, Stategraph Orchestration reaches Google Cloud with the key file of a service account. It gets a first plan running quickly. For production, [OIDC](/docs/orchestration/cloud-providers/gcp/oidc) replaces the stored key with short-lived tokens.

Setup has two steps:

1. Create the service account and its key file with the gcloud CLI.
2. Store the key as a GitHub secret with the GitHub CLI, or as a GitLab CI/CD variable in the GitLab UI.

The runner gets the key as an environment variable, and the Google provider reads it there. See [Variables](/docs/orchestration/configuration/variables).

## Setup steps

Set your project ID for the commands below:

```bash
export PROJECT_ID="your-gcp-project-id"
```

1. Create a dedicated service account for Orchestration in your project:

```bash
gcloud iam service-accounts create stategraph \
--description="Stategraph service account" \
--display-name="Stategraph" \
--project="$PROJECT_ID"
```

2. Grant the service account a role on the project. `roles/editor` is a starting point for testing and development. For production, use a custom or predefined role that grants only the permissions that Orchestration needs.

```bash
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
--member="serviceAccount:stategraph@$PROJECT_ID.iam.gserviceaccount.com" \
--role="roles/editor"
```

3. Create a service account key file:

```bash
gcloud iam service-accounts keys create stategraph-service-account-key.json \
--iam-account="stategraph@$PROJECT_ID.iam.gserviceaccount.com"
```

The key file contains a private key. Keep it out of version control.

4. Store the key as `GOOGLE_CREDENTIALS` for your VCS, as below. Then Orchestration can run `stategraph plan` and `stategraph apply` against your GCP resources.

### GitHub

Add the key file as the `GOOGLE_CREDENTIALS` secret on your GitHub repository, and delete the local copy:

```bash
export REPO="your-org/your-repo"

gh secret --repo "$REPO" set GOOGLE_CREDENTIALS < stategraph-service-account-key.json
rm stategraph-service-account-key.json
```

### GitLab

GitLab cannot mask a key file, because it is multi-line JSON. Store it as a CI/CD variable of type File. For each job, GitLab writes the value to a temporary file and sets `GOOGLE_CREDENTIALS` to the path of that file. The Google provider accepts the key itself or a path to it.

1. Open your GitLab project and go to **Settings**, then **CI/CD**, then **Variables**.
2. Click **Add variable**.
3. Set **Type** to **File**.
4. Enter the **Key** `GOOGLE_CREDENTIALS` and paste the contents of `stategraph-service-account-key.json` as the **Value**.
5. Leave **Protect variable** cleared, then click **Add variable**.
6. Delete the local key file:

```bash
rm stategraph-service-account-key.json
```

GitLab passes protected variables only to pipelines on protected branches. Orchestration runs plans on the merge request's source branch, so those runs do not get a protected variable. To share the key across projects, add the variable to the GitLab group.

## Security considerations

A service account key is a long-lived secret:

- Create new service account keys periodically, and delete the old ones.
- Use Cloud Audit Logs to review what the `stategraph` service account does.

## Next Steps

- [Configuration](/docs/orchestration/configuration): customize workflows in `.stategraph/config.yml`
- [GCP OIDC](/docs/orchestration/cloud-providers/gcp/oidc): migrate to keyless authentication
- [Cloud credentials](/docs/orchestration/security/cloud-credentials): credential patterns across providers
