---
title: Rollbacks
description: Revert an applied infrastructure change by reverting the pull request that introduced it, then reviewing and applying the resulting plan.
order: 3
---


To roll back an applied change with Stategraph Orchestration, revert the pull request that made it, then review and apply the plan. Your infrastructure returns to its previous state, and the history stays in Git.

## Performing a rollback

1. In the pull request list of your repository, find the pull request that introduced the unwanted change.
2. Create a revert pull request:
    - On GitHub, click **Revert** at the bottom of the merged pull request. GitHub opens a new pull request with the inverse change.
    - On GitLab, click **Revert** on the merged merge request, and start a new merge request with the revert commit.
3. Wait for the plan. Orchestration plans the revert pull request like any other.
4. Read the plan output. Make sure that it undoes what you expect and nothing more. A revert can plan a destroy.
5. Comment `stategraph apply` on the revert pull request, then merge it.

The plan uses the revert branch merged with the current tip of the destination branch, so it includes the changes merged after the original pull request. See [Plans run on the merge result](/docs/orchestration/workflows).

## Best practices

- Review and test Terraform changes before you merge. This prevents most rollbacks.
- Give pull requests clear titles and descriptions, so that you can find the change to revert later.
- Use branches and tags to keep a clear history of infrastructure changes.

## Next Steps

- [Pull request workflow](/docs/orchestration/workflows): plan, apply, and merge.
- [Drift detection](/docs/orchestration/governance/drift-detection): find changes made outside of pull requests.
