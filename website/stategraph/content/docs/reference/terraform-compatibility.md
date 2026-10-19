---
title: Terraform CLI Compatibility
description: See how each Terraform CLI command and HCL construct maps to Stategraph: direct equivalents, transaction replacements, and gaps.
order: 2
---


This page maps each Terraform and OpenTofu CLI command, and the HCL constructs that replace some of them, to the closest command of the [`stategraph` CLI](/docs/cli). The `stategraph` CLI plans and applies with Infrastructure as a Database, and runs Terraform or OpenTofu for you.

For each command, the tables show one of these:

- A direct equivalent.
- The part of the transaction model that replaces it.
- No equivalent, because Stategraph does not need one.

The tables also mark the commands that exist only in Terraform, not in OpenTofu: `query`, `stacks`, and `state identities`.

`stategraph plan` and `stategraph apply` are also pull request comments. In a comment, they tell Stategraph Orchestration to plan or apply on your CI runner, with the tool that you choose: the `stategraph` CLI, Terraform, OpenTofu, Terragrunt, Pulumi, CDKTF, or a custom command. See [Pull request commands](/docs/reference/orchestration/commands) and the [`engine`](/docs/reference/orchestration/configuration/engine) key.

## Lifecycle

| Terraform | Stategraph | Notes |
|-----------|------------|-------|
| `terraform init` | None | No working directory to initialize. Commands take the HCL directly. |
| `terraform plan` | `stategraph tf plan` (alias: `stategraph plan`) | Plans against the state in Stategraph, and records the changes in a transaction. |
| `terraform apply` | `stategraph tf apply` (alias: `stategraph apply`) | Materializes the minimal HCL subset, and applies it. |
| `terraform destroy` | None | Delete a whole state with `stategraph states delete`. Remove single resources with the refactor or transaction model. |
| `terraform refresh` | None | State comes from imports and applies. |
| `terraform validate` | `stategraph hcl eval`, `stategraph hcl json` (partial) | HCL parsing and evaluation. |
| `terraform fmt` | None | Out of scope. |
| `terraform console` | `stategraph sql query` (alias: `stategraph query`) | SQL queries over your infrastructure, not an HCL expression REPL. |
| `terraform show` (plan file) | `stategraph tf show` | Plan files only. |
| `terraform show` (state) | `stategraph states export`, `stategraph states summary` | |
| `terraform output` | `stategraph sql query` | No `output` command. |
| `terraform graph` | None | No Graphviz/DOT export. For dependencies, use `stategraph states instances blast-radius` (alias: `stategraph blast-radius`) or the [Graph Explorer](/docs/infrastructure-as-a-database/query/graph-explorer). |
| `terraform providers` | `stategraph states summary` | Shows the providers of each state. |
| `terraform test` | None | |
| `terraform metadata functions` | None | |
| `terraform modules` | `stategraph states modules list` | Lists the modules of a stored state, not of the working directory. Terraform only. |
| `terraform query` | None | Terraform only. Runs `list` blocks to search remote infrastructure. |
| `terraform stacks` | None | Terraform only. Manages HCP Terraform Stacks. Out of scope. |

## Plan and apply flags

Stategraph supports a subset of the `terraform plan` and `terraform apply` flags.

| Terraform flag | Stategraph | Notes |
|----------------|------------|-------|
| `-var=NAME=VALUE` | `stategraph tf plan --var ...` | Pass-through. |
| `-var-file=FILE` | `stategraph tf plan --var-file ...` | Pass-through. |
| `-refresh=false` | `stategraph tf plan --skip-refresh` | |
| `-target=ADDRESS` | `stategraph tf plan --force` | Takes glob patterns, not the Terraform address syntax. |
| `-detailed-exitcode` | `stategraph tf plan --detailed-exitcode` | The same exit codes as Terraform and OpenTofu. Also on `stategraph tf mtx`. |
| `-auto-approve` | `stategraph tf apply --auto-approve` | Skips the approval prompt when `stategraph tf apply` has no plan file. |
| `-out=FILE` | `stategraph tf plan --out ...` | Saves the plan for `stategraph tf apply`. Without it, the plan is a read-only preview. |
| `-replace=ADDRESS` | None | |
| `-refresh-only` | None | |
| `-destroy` | None | |

## State manipulation

| Terraform | Stategraph | Notes |
|-----------|------------|-------|
| `terraform state list` | `stategraph states list`, `stategraph states resources summary`, `stategraph states instances query` | Different views of resources and instances. |
| `terraform state show` | `stategraph states export`, `stategraph sql query` | To show one instance, query it with SQL. |
| `terraform state mv` | `stategraph refactor start` / `step` / `complete` | A refactor session moves addresses. Also see the [`moved` block](#hcl-native-alternatives-to-state-commands). |
| `terraform state rm` | `stategraph states delete` (whole state); refactor flow (per-resource) | |
| `terraform state pull` | `stategraph states export` | Exports the full state. |
| `terraform state push` | `stategraph import tf --overwrite`, `stategraph states import` | `import tf --overwrite` replaces the contents of an existing state. `states import` creates a new state from a state file. See [Import](/docs/cli/import). |
| `terraform state replace-provider` | None | |
| `terraform state identities` | None | Terraform only. Lists resource identities. |
| `terraform import` | `stategraph import tf`, `stategraph import tf --hcl`, `stategraph states import` | Onboards state and HCL from a directory or file. `--hcl` imports only the HCL. `stategraph hcl import` is deprecated. Also see the [`import` block](#hcl-native-alternatives-to-state-commands). |
| `terraform taint` / `untaint` | None | Terraform deprecates them in favor of `-replace` on apply. Stategraph does not support `-replace` either. |
| `terraform force-unlock` | `stategraph tx abort` | Transactions replace state file locks. |

## HCL-native alternatives to state commands

HCL blocks replace some Terraform state commands. Stategraph support differs by block.

| Terraform HCL | Replaces | Stategraph |
|---------------|----------|------------|
| `moved` block (Terraform 1.1+) | `terraform state mv` | `stategraph refactor complete` writes the renames and module moves that it detects into `moved_stategraph.tf`. Evaluation parses, de-duplicates, and keeps the `moved` blocks in your HCL. |
| `import` block (Terraform 1.5+) | `terraform import` (CLI) | Evaluated. Stategraph parses `import` blocks and tracks their dependencies, passes them to Terraform or OpenTofu at apply, and rewrites their `to` address to match the reified module layout. To onboard an existing state, use `stategraph import tf`. |
| `removed` block (Terraform 1.7+) | `terraform state rm` | Evaluated. Stategraph parses `removed` blocks, passes them to Terraform or OpenTofu at apply, and rewrites their `from` address to match the reified module layout. Terraform then honors the block as written: for example, `lifecycle { destroy = false }` removes the resource from state and does not destroy it. |
| `check` block (Terraform 1.5+) | Pre/post-condition assertions | Stategraph adds the references to the dependency graph, but does not enforce the assertions. |
| `lifecycle { ignore_changes }` | Selective `refresh` control | Stategraph evaluation does not honor it. |
| `lifecycle { prevent_destroy }` | Guard against accidental destroy | Stategraph evaluation does not honor it. |
| `lifecycle { create_before_destroy }` | Apply ordering | Stategraph passes it to Terraform at apply time. |
| `lifecycle { replace_triggered_by }` (Terraform 1.2+) | Replacement for `taint` | Stategraph passes it to Terraform at apply time, and keeps the referenced resource as a boundary, not literalized, so Terraform or OpenTofu honors the replacement. `terraform_data.triggers_replace` is also supported. |
| `variable { ephemeral = true }` (Terraform 1.10+) | Keeping per-run values (tokens, credentials) out of plan and state | `stategraph config tfvar ephemeral add <glob>` marks matching tfvars as ephemeral in `stategraph.json`. Stategraph passes an ephemeral tfvar to the run, but never stores it in the database. See [Config commands](/docs/cli/config). |
| `file()`, `templatefile()`, `fileset()` reading files next to the HCL | Files shipped with the configuration | `stategraph config files attach` records in `stategraph.json` which files belong to a change. See [Config commands](/docs/cli/config). |

## Workspaces

| Terraform | Stategraph | Notes |
|-----------|------------|-------|
| `terraform workspace new` | `stategraph states create --workspace` | A workspace maps to a Stategraph state. |
| `terraform workspace select` | `stategraph states resolve` | Gives the state ID of a workspace. |
| `terraform workspace list` | `stategraph states list` | |
| `terraform workspace show` | `stategraph info` | Shows the current context: user, tenants, and server. |
| `terraform workspace delete` | `stategraph states delete` | |

## Backend configuration

State lives in Stategraph, not in a Terraform backend. `stategraph import tf` onboards a workspace: it imports the state and the HCL, and connects the repository to a Stategraph state group through `stategraph.json`.

| Terraform | Stategraph | Notes |
|-----------|------------|-------|
| `terraform { backend "..." { ... } }` | `stategraph import tf` + `stategraph.json` | No backend block. |
| Backend `lock` / `unlock` | None | Transactions manage concurrency. |

## Auth and miscellaneous

| Terraform | Stategraph | Notes |
|-----------|------------|-------|
| `terraform login` / `logout` | (handled out of band) | Auth comes from the tenant and user setup. See `stategraph user whoami` and `stategraph info`. |
| `terraform version` | `stategraph version client`, `stategraph version server` | |
| `terraform get` | None | No module fetch step. |

## Stategraph-only commands

These commands have no Terraform equivalent.

| Command | Purpose |
|---------|---------|
| `stategraph tx create` / `list` / `abort` / `logs list` | Transactional change model |
| `stategraph tf mtx` | Multi-state transactions |
| `stategraph states instances blast-radius` (alias: `stategraph blast-radius`) | Dependency and dependent analysis |
| `stategraph tenant gaps analyze` (alias: `stategraph gaps`) | Find unmanaged cloud resources |
| `stategraph sql query` / `schema` | SQL across infrastructure |
| `stategraph states anonymize` | Anonymize state JSON |
| `stategraph user tenants list` | The tenants of the user |
| `stategraph security scan` / `scans list` / `findings list` / `findings summary` / `history` / `impact` | Security: on-demand scans, scan history, current findings, severity rollup, and transaction impact |
| `stategraph cost …` | Cost: manage billing sources and query cloud spend. See [Cost commands](/docs/cli/cost) |
| `stategraph capabilities default` / `group` (alias: `stategraph caps`) | Default capabilities and per-tenant group rules. See [Access tokens](/docs/admin/access-control/access-tokens) |
| `stategraph config files` / `tfvar ephemeral` | Client config in `stategraph.json`: attached files and ephemeral tfvars. See [Config commands](/docs/cli/config) |
| `stategraph diagnostics run` | Evaluate HCL and trace the evaluation. See [Diagnostics](/docs/cli/diagnostics) |

## See also

- [CLI overview](/docs/cli)
- [States commands](/docs/cli/states)
- [Transactions](/docs/cli/transactions)
- [Refactor](/docs/cli/refactor)
- [Pull request commands](/docs/reference/orchestration/commands)
