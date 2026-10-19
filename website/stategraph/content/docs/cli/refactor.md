---
title: Refactor
description: Track HCL refactors, such as resource renames and module moves, across plan steps and write Terraform moved blocks.
order: 7
---


`stategraph refactor` tracks HCL changes across a series of plans in one session, and writes Terraform `moved` blocks when you finish. Stategraph keeps the state mapping in sync, so you do not write each `moved` block by hand. For the guide, see [Refactoring](/docs/infrastructure-as-a-database/refactoring).

## When to use refactor mode

Use it for structural HCL changes, such as:

- Rename a resource (`aws_instance.web` to `aws_instance.frontend`)
- Move a resource into or out of a module
- Rename a module
- Restructure files with no change to the actual infrastructure

## Workflow

```bash
# 1. Start a session from your root module
stategraph refactor start

# 2. Make HCL edits, then run step to detect changes
stategraph refactor step

# 3. Continue editing and stepping until you're done
stategraph refactor step

# 4. Complete the session to write moved blocks
stategraph refactor complete
```

To discard the session:

```bash
stategraph refactor abort
```

The session state is in the `.stategraph` directory of your root module.

## Commands

### `stategraph refactor start`

Starts a session, and takes a snapshot of the current HCL and state as the base for later `step` calls.

```bash
stategraph refactor start
```

### `stategraph refactor step [OLD=NEW ...]`

Detects what changed since the last `start` or `step`, maps removed addresses to added addresses, and prints each mapping as `OLD -> NEW`. Run it as many times as you need.

When detection cannot find where something moved, `step` exits non-zero and lists the unmatched `added` and `removed` addresses. An example is a resource that you renamed and changed at the same time. Give explicit mappings, one for each argument:

```bash
stategraph refactor step aws_instance.web=aws_instance.frontend
```

### `stategraph refactor complete`

Ends the session, writes the mappings to a `moved` blocks file in your module, and prints the file name. Terraform and OpenTofu apply `moved` blocks on the next plan, so you do not need `terraform state mv`.

```bash
stategraph refactor complete
```

### `stategraph refactor abort`

Discards the session and its state. Use it to back out, or to start again from a bad session state.

```bash
stategraph refactor abort
```

## How plan and apply drive a session

When a session is active (a `.stategraph` directory is present), `stategraph tf plan` and `stategraph tf apply` run `step` and `complete` for you:

- `stategraph tf plan` runs a `step`, prints `WARNING: Running in refactor mode.`, and adds the detected `moved` blocks to the plan.
- If a move is ambiguous, the plan stops, lists the unmatched added and removed addresses, and prints `Run 'stategraph refactor step' to resolve.` Give the `OLD=NEW` mapping to `stategraph refactor step`, then plan again.
- `stategraph tf apply` also runs a step. After the commit succeeds, it prints `WARNING: Running in refactor mode. Finalizing refactor session.` and runs `complete`, which writes the `moved` blocks file and ends the session.

## Notes

- A session covers only the module where you ran `start`. Run it from the directory where you run `stategraph tf plan`.
- `stategraph tf mtx` does not drive a refactor session. Use [`tf plan`](/docs/cli/tf) and `tf apply` in the module directory.
- Do not commit `.stategraph/` during a refactor.
- Refactor mode handles moves that are visible in HCL. It does not handle changes in provider behavior, for example an upstream provider that renames an attribute.

## Next Steps

- [Refactoring](/docs/infrastructure-as-a-database/refactoring): restructure a repo without losing state.
- [Set up Infrastructure as a Database](/docs/infrastructure-as-a-database/setup): the `stategraph tf` plan and apply workflow.
- [CLI Overview](/docs/cli): the full command reference.
