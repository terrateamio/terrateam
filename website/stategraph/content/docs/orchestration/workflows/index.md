---
title: Pull Request Workflow
description: Stategraph Orchestration plans each pull request, posts plan comments and commit checks, applies the reviewed plan, and locks directories.
order: 1
---


Stategraph Orchestration plans each pull request, posts the plan as a comment and commit checks, applies the reviewed plan on a comment or on merge, and locks directories. It runs Terraform, OpenTofu, the `stategraph` CLI (see [Use with Orchestration](/docs/infrastructure-as-a-database/orchestration)), Terragrunt, Pulumi, CDKTF, or a custom command, as set by the [engine](/docs/reference/orchestration/configuration/engine) key.

## The flow

1. Create a branch, and make your Terraform changes. Commit and push.
2. Open a pull request against your default branch. Orchestration runs a plan on your CI runner for each directory with changed files that match your [when_modified](/docs/reference/orchestration/configuration/when-modified) patterns. Autoplan is on by default.
3. Review the plan. Orchestration posts the plan output as a comment on the pull request, and updates the commit checks.

<figure class="docs-figure" data-vcs="github">
<div class="docs-mock">
<div class="docs-mock-bar"><span class="docs-mock-avatar"><img src="/assets/logo-symbol.svg" alt=""></span><span class="vcs-github docs-mock-author">Stategraph GitHub App</span><span class="vcs-github docs-mock-badge">bot</span><span class="vcs-gitlab docs-mock-author">Access token user</span><span>commented</span><span class="docs-vcs-switch" role="group" aria-label="Provider"><button type="button" data-vcs-set="github" aria-pressed="true">GitHub</button><button type="button" data-vcs-set="gitlab" aria-pressed="false">GitLab</button></span></div><div class="docs-mock-body"><div class="docs-mock-h">Plans 👍</div><p>Outputs can be viewed in the Stategraph Console <span class="docs-mock-link">here</span>.</p><div class="docs-mock-h">Stategraph Plan Output 👍</div><details><summary>Expand for plan output details</summary><div class="docs-mock-details"><div class="docs-mock-h small">dev | default | Success 👍</div><div class="docs-mock-kv"><div><strong>Dir</strong>: dev</div><div><strong>Workspace</strong>: default</div><div><strong>Success</strong>: 👍</div></div><div class="docs-mock-kv"><div><strong>Step</strong>: tf/plan</div><div><strong>Success</strong>: 👍</div></div><pre>Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.dev.null_resource.this[0] will be created
  + resource &quot;null_resource&quot; &quot;this&quot; {
      + id = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.</pre></div></details><hr><p>To apply all these changes, comment:</p><pre>stategraph apply</pre><hr><details><summary><strong>Feedback?</strong></summary><p>Questions? Comments? Give feedback by commenting <code>stategraph feedback &lt;your msg&gt;</code>. Your message lands directly in our inbox.</p></details></div>
</div>
<figcaption>A plan comment on a pull request.<br> Expand the plan output to see each directory and workspace.</figcaption>
</figure>

4. Ask for reviews, and push more commits. Each push runs the plan again, so the plan stays current.
5. Comment `stategraph apply`. Orchestration checks the apply requirements, locks the affected directories, applies the stored plan, and posts the result.
6. Merge the pull request. A merge after a successful apply releases the lock.

## Comment commands

- `stategraph plan` runs a plan.
- `stategraph apply` applies the stored plan.

Both commands take a tag query that selects directories, for example `stategraph apply dir:production`. The [command reference](/docs/reference/orchestration/commands) lists the other commands, such as `stategraph apply-force`, `stategraph apply-autoapprove`, and `stategraph unlock`.

## Plan comments and commit checks

- Each run posts a comment with a summary, and with the plan or apply output for each directory and workspace.
- Each directory and workspace gets its own commit check, named `stategraph plan: <directory> <workspace>` or `stategraph apply: <directory> <workspace>`.
- The [notifications](/docs/reference/orchestration/configuration/notifications) key controls which comments and checks Orchestration posts.

With `apply_requirements.create_pending_apply_check: true`, a `stategraph apply` check stays pending until every changed directory is applied. Use it to stop a merge before the apply:

- On GitHub, require that check in branch protection.
- On GitLab, the check is a commit status on the merge request pipeline of the commit, when the project runs merge request pipelines. Require a successful pipeline before merge.

## Plans run on the merge result

Before each plan and apply, Orchestration fetches the current tip of the destination branch and merges it into your pull request branch. The operation runs on that merge result, not on your branch alone. So the plan shows what happens when the pull request lands on the destination branch.

### Plan output can change without a new commit

The merge uses the destination branch as it is when the run starts. If a teammate merges another pull request into `main`, your next plan uses the new `main`, although your branch did not change.

### A local plan can differ from the Orchestration plan

If your branch is behind the destination branch, `terraform plan` on your machine sees a different configuration. The usual symptom is a destroy in the local plan that is not in the pull request:

- Another pull request added a resource, applied it, and merged.
- Your branch does not declare that resource yet. Terraform on your machine finds it in state with no matching configuration, and plans a destroy.
- Orchestration merges the destination branch first. The merged configuration still declares the resource, so no destroy appears.

To get the Orchestration plan on your machine, merge the destination branch first:

```bash
git fetch origin
git merge origin/main
terraform plan
```

If the merge has conflicts, the run fails. Resolve the conflicts on your branch and push. Orchestration plans again.

## Apply runs the plan you reviewed, or it aborts

An apply does not compute a new plan. Orchestration applies the exact plan file that the plan run stored, so the plan output in the pull request comment is what runs.

An apply needs a valid plan for each directory and workspace that it changes. A stored plan is tied to the current commit of the pull request and to its base. It is no longer valid when:

- You push a new commit. With autoplan, Orchestration plans again.
- The last run for that directory failed.
- Another pull request applied or merged an overlapping directory after your plan was created.

When a directory or workspace in the operation has no valid plan, Orchestration aborts the apply before it starts. Nothing is applied, not even the directories with valid plans. Orchestration replies with a **Missing Plans** comment. The comment gives the reason for each missing plan, and names the pull request that superseded yours. Comment `stategraph plan` to make a new plan, then apply.

A superseded plan was computed against a state that no longer exists. Its apply could destroy resources that the other pull request just created, so Orchestration never applies a plan that it knows is out of date. A new plan is the full fix.

- `stategraph apply-force` does not skip this check. It skips apply requirements and Gatekeeper gates, not plan validity.
- Terraform and OpenTofu enforce the same rule. A saved plan file records the state that it was built from. After that state changes, an apply of the file fails with `Saved plan is stale`.
- One setting opts out of applying a stored plan: see [Plan file storage](/docs/orchestration/security/plan-file-storage).

## Apply requirements

Before an apply runs on an unmerged pull request, Orchestration checks the [apply_requirements](/docs/reference/orchestration/configuration/apply-requirements): approvals, merge conflicts, and status checks. A failed requirement blocks the apply, and the comment names it.

```yaml
apply_requirements:
  create_pending_apply_check: true
  checks:
    - tag_query: ""
      approved:
        enabled: true
        any_of_count: 1
      merge_conflicts:
        enabled: true
      status_checks:
        enabled: true
```

On GitLab, each requirement reads the merge request:

- Approvals are the users who approved the merge request. A `team:` entry in `any_of` or `all_of` names a GitLab group by its full path, and matches its direct members.
- Status checks are the commit statuses on the latest commit of the merge request, which include the jobs of its pipelines. Orchestration ignores its own `terrateam_job` job and `stategraph apply` status.
- Merge conflicts passes only when GitLab reports the merge request as mergeable, or as blocked only by its pipeline. Unresolved threads, a draft, or missing GitLab approvals also fail it.

[CODEOWNERS](/docs/orchestration/configuration/codeowners) enforcement and [Gatekeeper](/docs/orchestration/governance/gatekeeper) gates use the same mechanism.

## Apply before merge or after merge

By default, you apply before the merge: someone comments `stategraph apply`, then merges. Two settings change this:

- Apply after merge: with `when_modified.autoapply: true`, Orchestration applies when the pull request merges. See [Apply after merge](/docs/orchestration/workflows/apply-after-merge).
- Only after merge: with `apply_after_merge.enabled: true` in an apply requirements check, an apply can run only after the pull request merges.

```yaml
apply_requirements:
  checks:
    - tag_query: "production"
      apply_after_merge:
        enabled: true
```

## Locks

A lock stops two pull requests from applying changes to the same dirspace (a directory and a workspace) at the same time. A pull request owns each lock.

- A pull request takes the lock when it applies, or when it merges without an apply.
- After one dirspace of a pull request is applied, the pull request owns locks on every dirspace that it targets.
- The lock is released only after the change is applied and merged.
- Comment `stategraph unlock` to force the release of the locks of a pull request.

The [lock_policy](/docs/reference/orchestration/configuration/lock-policy) key changes when a pull request takes a lock. [Locks and concurrency](/docs/orchestration/workflows/advanced/lock-management) explains each policy and the results of the unlock command.

## Console and SQL

The console has a page for **Runs**, **Pull Requests**, **Stacks**, **Repositories**, **Workspaces**, **Drift**, and **Audit**. **Repositories** shows the effective configuration of each repository.

You can query runs, pull requests, gates, drift schedules, pull request stacks, and other Orchestration data with SQL, in the scope of your tenant. `stategraph sql schema` lists the tables. Query them like the rest of your infrastructure. See [Query](/docs/infrastructure-as-a-database/query/query).

## Next Steps

- [Apply after merge](/docs/orchestration/workflows/apply-after-merge): apply automatically when the pull request merges.
- [Rollbacks](/docs/orchestration/workflows/rollbacks): revert a merged change through a new pull request.
- [Performance](/docs/orchestration/workflows/performance): find where a run spends its time.
- [Locks and concurrency](/docs/orchestration/workflows/advanced/lock-management): lock policies and forced unlocks.
- [Tag system](/docs/orchestration/workflows/advanced/tag-system): target directories with tag queries.
- [Multi-environment](/docs/orchestration/workflows/advanced/multi-environment): staging and production from one repository.
- [Stacks](/docs/orchestration/workflows/advanced/stacks): dependencies between directories.
- [Command reference](/docs/reference/orchestration/commands): every pull request comment command.
