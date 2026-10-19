---
title: Diagnostics
description: Run stategraph diagnostics to trace how Stategraph evaluates your Terraform HCL on your machine, then send the trace to the Stategraph team.
order: 13
---


`stategraph diagnostics run` evaluates the HCL of your root module on your machine, and writes a trace of how Stategraph reads it. During onboarding, the Stategraph team asks for this trace, so that your first import is correct.

The command makes no API calls and uploads nothing, so it works before you configure a server, get an access token, or import a state. You decide what to send.

## Why new users run it

Codebases differ: nested modules, `for_each` over computed values, `file()` and `templatefile()` that read data from disk, and variables in layers of `.tfvars` files. The trace shows the team how your modules, variables, and file references evaluate, without access to your infrastructure, cloud accounts, or state. With it, the team can:

- find HCL patterns that need more configuration, such as files to attach to an address,
- confirm that your modules resolve as you expect.

## What the trace contains

The trace is a stream of `SG_TFEVAL_*` lines that you can grep, then a one-line rollup summary. It records structure, not secrets: types, reasons, origins, reference addresses, and expressions rendered back to HCL source. It never records the contents of an evaluated value.

Data-map keys are hidden by default, so a trace from a production module is safe to share. `SG_DIAG_SHOW_KEYS=1` shows them. Do not set it unless the team asks.

## Quickstart

From your root module directory, write the trace to a file:

```bash
# From your Terraform root module
stategraph diagnostics run --out diagnostics.txt
```

Then send `diagnostics.txt` to the Stategraph team. That is the whole onboarding step.

If your module needs variables, give the `--var` and `--var-file` flags that you give to `terraform plan`:

```bash
stategraph diagnostics run \
  --out diagnostics.txt \
  --var-file prod.tfvars \
  --var region=us-east-1
```

To trace a module in another directory, give it as the argument:

```bash
stategraph diagnostics run ./infra/networking --out networking-diagnostics.txt
```

For a quick look, omit `--out` and read stderr:

```bash
stategraph diagnostics run 2>&1 | less
```

## Options

```bash
stategraph diagnostics run [options] [DIR]
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `DIR` | No | Root module directory to evaluate. Default: the current directory. |

### Options

| Option | Required | Description |
|--------|----------|-------------|
| `--out` | No | File for the trace. Without it, the trace goes to stderr. For onboarding, always use it, so that you have a file to send. |
| `--workspace` | No | Workspace to evaluate (default: `default`, or set `STATEGRAPH_WORKSPACE`). |
| `--var` | No | Set a variable (`key=value`, repeatable). |
| `--var-file` | No | Path to a variable file (repeatable). |
| `--attach-files` | No | Attach files to resources that match an address glob (`ADDRESS_GLOB=FILE_GLOB`, repeatable). Use it only when the team asks you to reproduce a file-attachment case. |
| `--attach-dest` | No | Destination directory for attached files (`ADDRESS_GLOB=DEST`, repeatable). |
| `--mode` | No | Detail level: `rollup`, `on`, `detail`, `verbose` (default), or `perf`. |

`verbose` is the full step-by-step trace, and the level that onboarding needs. It writes one line per evaluated expression, so the file for a very large module can be big. The file compresses well.

`perf` prints nothing during evaluation, and then only the `SG_TFEVAL_PERF*` timing breakdown, with the phase totals `SG_TFEVAL_PERF_PIPELINE` and `SG_TFEVAL_PERF_TX`. The team can ask for it to examine a slow evaluation, not a correctness problem.

## Reading the output (optional)

Each line is a `key=value` record:

| Line | What it reports |
|------|-----------------|
| `SG_TFEVAL_ROOT` | The root module directory and the workspace of the run. |
| `SG_TFEVAL_NODE` | A resolved node (variable, local, output, module input) and its outcome. |
| `SG_TFEVAL_ATTR` | A resource attribute, and whether it resolved, was unresolved, or was dropped. |
| `SG_TFEVAL_REF` | A reference between values, and how its address resolved. |
| `SG_TFEVAL_FILE` | A `file()` / `templatefile()` / `fileset()` reference, and any failure or warning. |
| `SG_TFEVAL_MODULE` | A module bridge and its declared-input reconciliation. |
| `SG_TFEVAL_VALIDATION` | A `variable` validation block: its `condition` expression and outcome. |
| `SG_TFEVAL_META` | Value shapes for `count` / `for_each` pruning (`detail` and above). |
| `SG_TFEVAL_COERCE` | The coercion explanation for each field (`detail` and above). |
| `SG_TFEVAL_STEP` | One line per evaluated expression node (`verbose`). |
| `SG_TFEVAL_ROLLUP` | The end-of-run summary: counts of nodes, unresolved and dropped values, file failures, missing variables, coercions, and more. |

To see the shape of a run, read the last line:

```bash
grep SG_TFEVAL_ROLLUP diagnostics.txt
```

To find anything that did not resolve cleanly:

```bash
grep 'outcome=dropped' diagnostics.txt
grep 'resolution=undefined' diagnostics.txt
```

The rollup alone often gives the team most of what it needs. To check your module first, look for `node_dropped`, `file_failures`, or `vars_missing` counts above zero.

## What to send

```bash
stategraph diagnostics run --out diagnostics.txt --var-file prod.tfvars
# then attach diagnostics.txt to your onboarding thread
```

For several root modules, send one file per module, with names that tell them apart. Zip a large file first. You can share the trace as it is, or read it first.

## Next steps

- [Import](/docs/cli/import): import a state and its HCL after clean diagnostics.
- [Set up Infrastructure as a Database](/docs/infrastructure-as-a-database/setup): the full onboarding flow.
- [HCL Commands](/docs/cli/hcl): list addresses and evaluate expressions.
- [Troubleshooting](/docs/reference/troubleshooting): common evaluation problems.
- [Support](/docs/support): where to send the trace.
