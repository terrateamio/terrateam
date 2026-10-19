---
title: parallel_runs
description: Reference for the parallel_runs key in .stategraph/config.yml. Set how many Terraform runs execute concurrently across directories.
order: 19
---


`parallel_runs` sets how many Terraform runs Stategraph Orchestration executes at the same time, across directories or environments. Parallel runs make changes faster, mostly in large projects.

## Default Configuration

```yaml
parallel_runs: 3
```

## Keys

| Key | Type | Description |
| --- | --- | --- |
| `parallel_runs` | integer | The maximum number of Terraform runs at the same time. Default is `3`. |

- A higher value can make a run faster, but can need more resources.
- Make sure that your infrastructure can accept the parallel runs without bottlenecks or throttling.
- Parallel runs suit directories and environments that can run at the same time.

## Example Configuration

```yaml
parallel_runs: 5
```

This configuration sets the maximum to 5 parallel runs.

## Related

- [batch_runs](/docs/reference/orchestration/configuration/batch-runs)
- [Performance](/docs/orchestration/workflows/performance)
