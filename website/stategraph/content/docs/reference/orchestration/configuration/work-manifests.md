---
title: work_manifests
description: Reference for work_manifests in .stategraph/config.yml. Set how long a run has to call home and how long it may run before Orchestration aborts it.
order: 27
---


`work_manifests` sets how long a run has to call home before Stategraph Orchestration treats it as stale and aborts it. A run that never starts holds the directories and workspaces of its operation, and the work behind it waits with no end.

`work_manifests` also sets how long a running run may run before the hourly sweep aborts it. A run that stops in the middle holds its directories and workspaces with no end as well.

## Default Configuration

```yaml
work_manifests:
  start_timeout_sec: 180
  stale_timeout_sec: 86400
```

## Keys

| Key | Type | Description |
| --- | --- | --- |
| `start_timeout_sec` | integer | Seconds that a dispatched run has to call home before Orchestration aborts it as stale. Default is `180`. The value must be at least `1` and at most `2147483647`, a value outside that range is a configuration error. |
| `stale_timeout_sec` | integer | Seconds that a run may stay in the `running` state before the hourly sweep aborts it. Default is `86400`, one day. The value must be at least `1` and at most `2147483647`, a value outside that range is a configuration error. |

## When a run counts as stale

A run calls home the first time its runner polls the server. The count starts when Orchestration dispatches the run, not when the run enters the queue, so a run that waits in the queue a long time is not stale.

Orchestration runs the check when an operation requests directories and workspaces that a running run already holds. It aborts the run when all of these hold:

- The run state is `running`.
- The runner never polled, so the run has no run id.
- The run has been dispatched for longer than `start_timeout_sec` seconds.
- The run belongs to no run of the operation that you requested.

The abort is silent: Orchestration posts no comment for it. The run becomes `aborted`, its directories and workspaces are free, and the work that waited behind it starts.

A run that has no dispatch time, one from before Orchestration recorded it, is never stale.

!!! note "A run that started is not aborted by the start check"
    A run that called home passes the start check, however long it runs. A run that has been in flight for over an hour instead blocks the operation and posts a **Potentially Stale Operations Detected** comment with the [`stategraph unlock`](/docs/reference/orchestration/commands/unlock) command to clear it. The sweep of the next section still aborts such a run when it runs longer than `stale_timeout_sec`.

## When a running run is swept

Orchestration sweeps for stale runs once an hour. The sweep is one statement for every repository of the installation, and it aborts a run when all of these hold:

- The run state is `running`.
- The run started more than `stale_timeout_sec` seconds ago.

The age of a run starts when Orchestration dispatches it, as it does for `start_timeout_sec`, so a run that waited in the queue a long time is not swept the moment it starts. A run that has no dispatch time, one from before Orchestration recorded it, counts from the time it entered the queue. The sweep reads no run id and no poll: a run that called home once and then stopped is read the same as a run that never polled. One day is longer than any run a healthy repository produces, thus the default holds for every repository that sets no value.

The sweep reads `stale_timeout_sec` from the derived configuration of the run, which is the configuration of the repository at the (branch, sha) of the run. A run whose stored configuration is gone falls back to the default of one day. The sweep keeps at most 100 runs per hour, and a sweep that cannot keep up leaves the rest to the next hour.

The abort is silent: Orchestration posts no comment for it. The run becomes `aborted`, its directories and workspaces are free, and the work that waited behind it starts.

## Configuration file only

Orchestration reads `start_timeout_sec` from `.stategraph/config.yml` in the repository. A configuration that a config builder or tree builder run produced cannot set it, because such a run is a work manifest itself: a run must never decide when Orchestration aborts runs.

The sweep is one statement for every repository, and it reads `stale_timeout_sec` from the derived configuration of the repository instead. A configuration that a config builder run produced can thus set `stale_timeout_sec`.

## Example Configuration

```yaml
work_manifests:
  start_timeout_sec: 600
  stale_timeout_sec: 172800
```

A repository whose runners start slowly can raise `start_timeout_sec` to 600 seconds, so that a slow start is not read as a failure to start. A repository whose apply step runs for more than a day can raise `stale_timeout_sec` to 172800 seconds, two days, so that the sweep does not abort a run that still works.

## Related

- [Stale runs](/docs/orchestration/workflows/stale-runs): a run that is valid but used files that are no longer at the head. It is a different meaning of stale.
- [batch_runs](/docs/reference/orchestration/configuration/batch-runs): which steps of one job share a CI run
- [stategraph unlock](/docs/reference/orchestration/commands/unlock): clear a run that blocks an operation
- [Troubleshooting](/docs/reference/troubleshooting#apply-is-waiting-on-work-already-running)