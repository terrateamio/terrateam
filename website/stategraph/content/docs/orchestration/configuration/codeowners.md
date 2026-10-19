---
title: CODEOWNERS
description: Block applies until the code owners your VCS requires have approved the pull request, using require_completed_reviews in apply requirements.
order: 5
---


Stategraph Orchestration can block an apply until the code owners of the changed files approve the pull request. The apply gate then matches the merge gate, for organizations where different teams own different parts of the infrastructure. On GitHub, Orchestration reads the review verdict of GitHub. On GitLab, it reads the reviewers of the merge request. [Requirements](#requirements) covers both.

!!! note "Enterprise"
    CODEOWNERS enforcement with `require_completed_reviews` is an Enterprise feature. It is included in Stategraph Cloud and in self-hosted Enterprise deployments. The Open Source edition rejects `require_completed_reviews: true`, and a comment on the pull request tells why. See [Editions](/docs/get-started/editions).

## Configuring CODEOWNERS enforcement

Set `require_completed_reviews` under `approved` in your [apply requirements](/docs/reference/orchestration/configuration/apply-requirements). An apply then waits until each required CODEOWNERS review is complete.

### Basic configuration

Enforce CODEOWNERS approval for every directory:

```yaml
apply_requirements:
  checks:
    - tag_query: ''
      approved:
        enabled: true
        require_completed_reviews: true
```

Orchestration does not parse the CODEOWNERS file, and you do not repeat it in `.stategraph/config.yml`. When a path has more than one owner, [an approval from any one of them](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners) satisfies both gates.

### Environment-specific enforcement

Use tag queries to enforce CODEOWNERS approval only where you need it:

```yaml
apply_requirements:
  checks:
    - tag_query: 'production'
      approved:
        enabled: true
        require_completed_reviews: true
    - tag_query: 'staging'
      approved:
        enabled: true
        require_completed_reviews: false
    - tag_query: 'development'
      approved:
        enabled: false
```

This configuration:

- Enforces CODEOWNERS approval for production.
- Allows applies in staging without completed CODEOWNERS reviews.
- Allows applies in development with no approval requirement.

## How it works

When `require_completed_reviews: true` is set on GitHub:

1. A developer opens a pull request with Terraform changes.
2. GitHub requests reviews from the code owners of the changed files.
3. On a `stategraph apply` comment, Orchestration checks if the target directories need approval, and if GitHub reports the pull request as approved.
4. If GitHub reports the pull request as approved, the apply runs.
5. If a required review is still pending or has requested changes, Orchestration blocks the apply and lists the outstanding reviews.

## Requirements

### GitHub

The GitHub verdict includes code owners only when the target branch has a branch protection rule or ruleset with **Require review from Code Owners** enabled. Without it, CODEOWNERS still requests reviewers automatically, but GitHub does not make their approval mandatory, and Orchestration does not either.

Two other cases:

- Reviews required, but not from code owners: the verdict counts approvals from anyone, so `require_completed_reviews` enforces the approval count, not ownership.
- No reviews required: there is no verdict. Orchestration then requires that no review request on the pull request is still outstanding.

### GitLab

GitLab has no review verdict. With `require_completed_reviews: true`, Orchestration treats each reviewer of the merge request as an outstanding review request, whatever the state of that review. The apply stays blocked while the merge request lists a reviewer, and the blocking comment names each one.

To require approval from specific people or groups, list them in `all_of` or `any_of`. On GitLab, a `team:` entry names a GitLab group by its full path, and matches the direct members of the group:

```yaml
apply_requirements:
  checks:
    - tag_query: 'production'
      approved:
        enabled: true
        all_of: ['team:acme/sre']
```

This configuration blocks applies in production until at least one direct member of the `acme/sre` group approves the merge request.

## Next Steps

- [apply_requirements](/docs/reference/orchestration/configuration/apply-requirements): every approval, merge conflict, and status check option.
- [RBAC](/docs/orchestration/governance/rbac): control who can plan and apply.
- [Gatekeeper](/docs/orchestration/governance/gatekeeper): explicit approval gates for specific changes.
