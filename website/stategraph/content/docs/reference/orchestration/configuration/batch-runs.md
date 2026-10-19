---
title: batch_runs
description: Reference for the batch_runs key in .stategraph/config.yml. Limit how many workspaces a single CI run executes in large repositories.
order: 4
---


`batch_runs` sets how Stategraph Orchestration puts work into CI runs: the maximum number of workspaces in each run, and which steps can join a run that is already running. A CI run is a GitHub Actions workflow run or a GitLab pipeline. In a large repository, one run cannot always hold all workspaces because of CPU and disk space limits.

## Default Configuration

```yaml
batch_runs:
  enabled: false
  max_workspaces_per_batch: 1
  merge_steps: setup
```

## Keys

| Key | Type | Description |
| --- | --- | --- |
| `enabled` | boolean | Turns on `max_workspaces_per_batch`. It does not control `merge_steps`. Default is `false`. |
| `max_workspaces_per_batch` | integer | The maximum number of workspaces in each run. Orchestration creates more runs for the other workspaces. Default is `1`. |
| `merge_steps` | string | Which steps can join a run that is already running: `none`, `setup`, `setup_and_plan`, `all`, or `by_phase`. Default is `setup`. See [Merging steps](#merging-steps). |

Orchestration does not limit how many runs it starts at the same time. For example, a change with 100 workspaces and `max_workspaces_per_batch: 1` starts 100 runs on your CI runners at the same time.

## Merging steps

Orchestration puts the steps of a job into as few runs as it can, because many runs are slower than one run. `merge_steps` sets which steps can join a run that is already running. A step that the value does not permit always starts a run of its own.

Four of the values make a ladder of the highest step that can join:

| Value | The steps that can join a run |
| --- | --- |
| `none` | None. Each step gets a run of its own. |
| `setup` | The tree builder, the config builder and the indexer. |
| `setup_and_plan` | The steps above, and a plan. |
| `all` | The steps above, and an apply. A run of many layers then uses one run. |

The fifth value, `by_phase`, is not on that ladder. See [Phases](#phases).

A step joins a run only if the run can take it:

- The run has the same environment, the same `runs_on`, and the same refs.
- The cap `max_workspaces_per_batch` holds for the full run.

A step that cannot join gets a run of its own.

Orchestration reads `merge_steps` from the configuration file in the repository. A configuration from the config builder cannot set it, because the tree builder, the config builder and the indexer run before that configuration exists.

`merge_steps` changes only how many runs hold the work of a job. It cannot start an operation that the rest of the configuration does not permit, and it cannot stop an operation that the rest of the configuration permits. Automatic plans and applies happen in the same order with any value of this key.

## Phases

The steps of a job fall into two phases.

| Phase | The steps of the phase |
| --- | --- |
| Setup | The tree builder, the config builder and the indexer. |
| Layer | A plan and an apply. |

`merge_steps: by_phase` permits every step, as `all` does, but only into a run of the same phase. A run thus holds one phase, never both.

```yaml
batch_runs:
  merge_steps: by_phase
```

Use `by_phase` when the setup steps of a job must keep a run of their own, and the layers of that job must still share one run.

### Example

A pull request has the three setup steps and three layers. The first two layers have no changes, so Orchestration plans the next layer without a comment from a user. The third layer has a change and stops the job at the plan comment.

| Value | The runs |
| --- | --- |
| `none` | Six. One for each step. |
| `setup` | Four. One for the three setup steps, and one for each layer. |
| `setup_and_plan` | One. A plan joins the run of the setup steps. |
| `all` | One. The same as above, and an apply would join as well. |
| `by_phase` | Two. One for the three setup steps, and one for the three layers. |

These counts do not include one more run. The tree builder of a pull request also builds the tree of the destination branch. That build has the ref of the destination branch, so it always takes a run of its own, whatever the value of `merge_steps`.

## Related

- [parallel_runs](/docs/reference/orchestration/configuration/parallel-runs)
- [Performance](/docs/orchestration/workflows/performance)
