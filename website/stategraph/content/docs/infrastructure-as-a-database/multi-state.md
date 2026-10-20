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

`stategraph tf plan` adds the resources in other states that your change reaches through `terraform_remote_state` to the same transaction. The data source must use `backend = "http"` and the address `https://stategraph/<state-id>`. The address can read variables and locals. See [Variables in the address](#variables-in-the-address).

## Variables in the address

The address of a `terraform_remote_state` data source can read input variables and locals. Stategraph resolves the address at plan time, and takes the state id from the result. A literal address works as it does today and needs no variable.

```hcl
variable "network_state_id" {
  type    = string
  default = "11111111-1111-1111-1111-111111111111"
}

data "terraform_remote_state" "network" {
  backend = "http"
  config = {
    address = "https://stategraph/${var.network_state_id}"
  }
}
```

The value comes from a tfvar, from the `default` of the variable, or from the argument that a module call passes. A tfvar wins over the `default`. An address can hold more than one variable, and a variable can hold the whole address:

```hcl
# Two variables in one address.
address = "${var.scheme}://stategraph/${var.network_state_id}"

# One variable, the whole address.
address = var.network_url
```

A block inside a module works the same way. The module call passes the value, and Stategraph resolves the block for each call of the module.

Change the tfvar, and the next plan reads the other state. You do not change the HCL of the data block.

### Limitations

- The address must be evaluable at plan time. Stategraph reads tfvars, variable `default`s, locals, and the arguments of module calls. It does not run your configuration, so a value that comes from a resource, a data source, or an output does not resolve.
- `count.index`, `each.key`, and `path.*` do not resolve in an address.
- The value must be a string.
- The run fails only when your change reads a block that does not resolve. Stategraph refuses the plan before Terraform or OpenTofu runs, and prints the data block, the address that does not resolve, and the cause. See [Remote state address does not resolve](/docs/reference/troubleshooting#remote-state-address-does-not-resolve).
- Stategraph joins a state to your change only when the block has `backend = "http"` and an address that starts with `https://stategraph/`. Any other block joins no state, and Stategraph does not fail the run for it.

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
