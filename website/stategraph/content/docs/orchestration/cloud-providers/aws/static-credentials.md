---
title: AWS static credentials
description: Create an IAM user with access keys and store them as GitHub secrets or GitLab CI/CD variables so Stategraph Orchestration can reach AWS.
order: 3
---

With static credentials, Stategraph Orchestration reaches AWS with the access keys of an IAM user. It gets a first plan running quickly. For production, [OIDC](/docs/orchestration/cloud-providers/aws/oidc) replaces stored keys with short-lived tokens.

Setup has two steps:

1. Create the IAM user and its access keys with the AWS CLI.
2. Store the keys as GitHub secrets with the GitHub CLI, or as GitLab CI/CD variables in the GitLab UI.

The runner gets the keys as environment variables, and the AWS provider reads them there. See [Variables](/docs/orchestration/configuration/variables).

## Setup steps

1. Create a dedicated IAM user for Orchestration:

```bash
aws iam create-user --user-name stategraph
```

2. Attach a permissions policy to the user. `PowerUserAccess` is a starting point for testing and development. For production, use a custom policy that grants only the permissions that Orchestration needs.

```bash
aws iam attach-user-policy \
--policy-arn arn:aws:iam::aws:policy/PowerUserAccess \
--user-name stategraph
```

3. Create access keys for the user:

```bash
aws iam create-access-key --user-name stategraph
```

Output:

```json
{
  "AccessKey": {
    "UserName": "stategraph",
    "AccessKeyId": "AKIAIOSFODNN7EXAMPLE",
    "Status": "Active",
    "SecretAccessKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  }
}
```

Copy `AccessKeyId` and `SecretAccessKey`. AWS shows the secret access key only one time.

4. Store the access keys for your VCS, as below. Then Orchestration can run `stategraph plan` and `stategraph apply` against your AWS resources.

### GitHub

Add the keys as secrets to your GitHub repository. Paste the values from the previous step when the CLI asks for them.

```bash
export REPO="your-org/your-repo"

gh secret --repo "$REPO" set AWS_ACCESS_KEY_ID
gh secret --repo "$REPO" set AWS_SECRET_ACCESS_KEY
```

### GitLab

Add the keys as CI/CD variables on your GitLab project:

1. Open your GitLab project and go to **Settings**, then **CI/CD**, then **Variables**.
2. Click **Add variable**.
3. Enter the **Key** `AWS_ACCESS_KEY_ID` and paste the **Value** from the previous step.
4. Mark the variable as masked, and leave **Protect variable** cleared.
5. Click **Add variable**, then do the same for `AWS_SECRET_ACCESS_KEY`.

GitLab passes protected variables only to pipelines on protected branches. Orchestration runs plans on the merge request's source branch, so those runs do not get a protected variable. To share the keys across projects, add the variables to the GitLab group.

## Security considerations

Access keys are long-lived secrets:

- Create new access keys periodically, and delete the old ones.
- Use AWS CloudTrail to review what the `stategraph` user does.
- Keep hooks and workflow steps from printing the keys.

## Next Steps

- [Configuration](/docs/orchestration/configuration): customize workflows in `.stategraph/config.yml`
- [AWS OIDC](/docs/orchestration/cloud-providers/aws/oidc): migrate to keyless authentication
- [Cloud credentials](/docs/orchestration/security/cloud-credentials): credential patterns across providers
