---
title: Apply Requirements and Overrides
description: Reference for the apply_requirements key in .stategraph/config.yml. Configure approvals, merge conflict and status checks, and overrides.
order: 2
---


`apply_requirements` in `.stategraph/config.yml` sets the checks that a pull request must pass before Stategraph Orchestration runs a `stategraph apply`, such as approvals, no merge conflicts, and passing status checks. They do not stop the autoapply after a merge. [Access control](/docs/reference/orchestration/configuration/access-control) sets who can override them.

By default, an apply has two requirements:

- The pull request has no merge conflicts.
- All status checks of the pull request passed.

## Configuring Apply Requirements

```yaml
apply_requirements:
  create_pending_apply_check: true
  checks:
    - tag_query: ""
      approved:
        enabled: true
        any_of: ["user:jane", "user:john"]
        any_of_count: 1
        all_of: []
      merge_conflicts:
        enabled: true
      status_checks:
        enabled: true
        ignore_matching:
          - "ci/.*"
```

With this configuration, an apply needs:

- At least 1 approval from `jane` or `john`.
- No merge conflicts.
- Passing status checks. Status checks that match the regular expression `ci/.*` do not count.

To set different requirements for different directories or workspaces, use one check entry for each `tag_query`:

```yaml
apply_requirements:
  checks:
    - tag_query: "dir:tf1"
      approved:
        enabled: true
        all_of: ["user:jane"]
    - tag_query: "dir:tf2"
      approved:
        enabled: true
        all_of: ["user:john"]
```

Here, a change in `tf1` needs an approval from `jane`, and a change in `tf2` needs an approval from `john`.

### `apply_requirements` Keys

| Key | Type | Description |
| --- | --- | --- |
| `checks` | list | The check entries. Orchestration uses the first entry whose `tag_query` matches a directory and workspace. `checks` can also be one object with the `approved`, `merge_conflicts`, and `status_checks` keys, for every directory and workspace. |
| `create_pending_apply_check` | boolean | Creates a pending `stategraph apply` commit status on the pull request until every directory and workspace with changes is applied. With branch protection, it blocks the merge until the apply completes. Default `true`. |
| `create_completed_apply_check_on_noop` | boolean | Also creates a completed `stategraph apply` commit status when the pull request changes nothing that Orchestration manages. The pull request can then merge when branch protection requires the check. Default `true`. |

### Check Entry Keys

| Key | Type | Description |
| --- | --- | --- |
| `tag_query` | string | The directories and workspaces of this entry. See [tag queries](/docs/reference/orchestration/configuration/tag-queries). Required. |
| `approved` | object | The approval requirement. See [`approved` check keys](#approved-check-keys). |
| `merge_conflicts` | object | `enabled` (boolean, default `true`): the pull request must have no merge conflicts. |
| `status_checks` | object | `enabled` (boolean, default `true`): all status checks must pass. `ignore_matching` (list): patterns of status check names that do not count. |
| `apply_after_merge` | object | `enabled` (boolean, default `false`): `true` permits the apply only after the pull request merges. |
| `require_ready_for_review_pr` | boolean | `true`: a draft pull request cannot apply. Default `true`. |

This entry requires the apply after the merge, and permits an apply of a draft pull request:

```yaml
apply_requirements:
  checks:
    - tag_query: ""
      apply_after_merge:
        enabled: true
      require_ready_for_review_pr: false
```

### `approved` Check Keys

| Key | Type | Description |
| --- | --- | --- |
| `enabled` | boolean | Turns on the `approved` check. Default `false`. |
| `any_of` | array | Approval rules. One match counts toward `any_of_count`. |
| `any_of_count` | integer | The number of different `any_of` matches that the check needs. Default `1`. |
| `all_of` | array | Approval rules that each need a matching approval. |
| `require_completed_reviews` | boolean | `true`: all reviewers that CODEOWNERS or the VCS requires must approve before the apply. Default `false`. Enterprise only. See [CODEOWNERS enforcement](#codeowners-enforcement-require_completed_reviews). |

The rules use the syntax of [access control rules](/docs/reference/orchestration/configuration/access-control#rule-syntax).

### CODEOWNERS Enforcement (`require_completed_reviews`)

!!! note "Enterprise"
    `require_completed_reviews` is an Enterprise feature, in [Stategraph Cloud](https://app.stategraph.cloud) and self-hosted Enterprise. On the Open Source edition, Orchestration rejects a configuration with `require_completed_reviews: true` and comments on the pull request. See [Editions](/docs/get-started/editions).

With `require_completed_reviews: true`, Orchestration blocks the apply until GitHub reports the pull request as approved. CODEOWNERS then gates the apply, not only the merge.

```yaml
apply_requirements:
  checks:
    - tag_query: ''
      approved:
        enabled: true
        require_completed_reviews: true
```

Orchestration does not parse CODEOWNERS. It reads the review verdict of GitHub for the pull request, so the apply gate and the merge gate of GitHub always agree:

- An approval from any one owner of a path satisfies that path ([GitHub rules](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)). When two teams own the same file, one approval is enough.
- `.stategraph/config.yml` does not need to repeat your CODEOWNERS file. A change to CODEOWNERS takes effect immediately.

For a verdict that includes code owners, the target branch needs a branch protection rule or ruleset with **Require review from Code Owners**. Two other cases:

- The branch requires reviews, but not from code owners. The verdict counts approvals and ignores who gave them, so `require_completed_reviews` enforces only the approval count.
- The branch requires no reviews. GitHub gives no verdict. Orchestration then requires that the pull request has no open review request.

On GitLab, `require_completed_reviews` always requires no open review request, because GitLab has no verdict. Each reviewer of the merge request counts as an open review request, whatever the review state.

For scoped examples, see the [CODEOWNERS enforcement guide](/docs/orchestration/configuration/codeowners).

## Apply Requirements on GitLab

On GitLab, Orchestration checks each requirement against the merge request:

- `approved`: an approval comes from a user who approved the merge request, or from a reviewer with the review state `reviewed`. The `user:`, `team:`, and `role:` rules match GitLab usernames, groups, and project roles. See [GitLab users, groups, and roles](/docs/reference/orchestration/configuration/access-control#gitlab-users-groups-and-roles).
- `merge_conflicts`: passes when GitLab reports the merge request as mergeable, or as blocked only by a pipeline that is running or must succeed. Any other failed GitLab merge check fails it, such as a merge conflict, a draft, unresolved threads, or missing GitLab approvals.
- `status_checks`: the commit statuses on the latest commit of the merge request, which include the jobs of its pipelines. The Orchestration job `terrateam_job` and the `stategraph apply` status do not count. `ignore_matching` applies to the status names.
- `create_pending_apply_check`: adds the `stategraph apply` commit status to the merge request pipeline.

## Access Control and Apply Overrides

[Access control](/docs/reference/orchestration/configuration/access-control) sets who can run each operation, and who can override the apply requirements. To turn it on, add this to `.stategraph/config.yml`:

```yaml
access_control:
  enabled: true
```

This policy grants each capability:

```yaml
access_control:
  enabled: true
  apply_require_all_dirspace_access: true
  plan_require_all_dirspace_access: false
  terrateam_config_update: ['*']
  unlock: ['*']
  policies:
    - tag_query: ''
      apply: ['role:maintain']
      apply_autoapprove: ['user:jane']
      apply_force: ['team:sre']
      apply_with_superapproval: ['role:write']
      plan: ['*']
      superapproval: ['user:john']
```

| Capability | Granted to | Lets the user |
| --- | --- | --- |
| `apply` | Users with the `maintain` role | Apply. |
| `apply_autoapprove` | `jane` | Nothing. Orchestration does not run `stategraph apply-autoapprove`. |
| `apply_force` | The `sre` team | Run [`stategraph apply-force`](/docs/reference/orchestration/commands/apply-force), which applies with no apply requirements. |
| `apply_with_superapproval` | Users with the `write` role | Apply after a user with `superapproval` approves the pull request. |
| `plan` | All users (`*`) | Plan. |
| `superapproval` | `john` | Give super approvals. |

Grant the override capabilities only to trusted users or groups who know the risks of an apply without its requirements.

## Related

- [access_control](/docs/reference/orchestration/configuration/access-control)
- [default_branch_overrides](/docs/reference/orchestration/configuration/default-branch-overrides)
- [CODEOWNERS enforcement](/docs/orchestration/configuration/codeowners)
- [Apply after merge](/docs/orchestration/workflows/apply-after-merge)
