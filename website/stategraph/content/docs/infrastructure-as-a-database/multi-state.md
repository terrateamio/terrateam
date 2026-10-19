---
title: Multi-state transactions
description: Plan and apply several Terraform states in one transaction: the states that a change reaches, or the directories you name.
order: 5
---


A multi-state transaction plans and applies several Terraform states together. Stategraph adds the states that your change reaches, or you name them with `stategraph tf mtx`.

- All states plan and apply as one Terraform run, with each state as a module.
- Stategraph resolves `terraform_remote_state` inside this run. Resources that refer to each other across states apply in dependency order.
- [Resource-level locking](/docs/infrastructure-as-a-database/resource-locking) finds overlapping changes across states at commit time.

## States that a change reaches

`stategraph tf plan` adds the resources in other states that your change reaches through `terraform_remote_state` to the same transaction. The data source must use `backend = "http"` and the address `https://stategraph/<state-id>`.

## Directories that you choose

Name the directories after `stategraph tf mtx`. `--out` is required.

```bash
stategraph tf mtx --tenant <tenant-id> --out plan.json ./networking ./compute ./application
```

Each directory must contain a `stategraph.json`. `mtx` plans all workspaces in its group, so one directory can add several states. Apply the plan as usual:

```bash
stategraph tf apply plan.json
```

`mtx` does not run a [refactor session](/docs/infrastructure-as-a-database/refactoring).

## Next steps

- [Transactions](/docs/infrastructure-as-a-database/transactions): the transaction lifecycle.
- [Terraform commands](/docs/cli/tf): all `tf mtx` flags.
