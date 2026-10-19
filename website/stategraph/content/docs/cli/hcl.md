---
title: HCL Commands
description: Use the stategraph hcl commands to list Terraform addresses, evaluate expressions, convert HCL and JSON, and import HCL into a state.
order: 9
---


The `stategraph hcl` commands list the addresses in your Terraform HCL, evaluate HCL expressions, and convert HCL to and from JSON. They run locally and do not contact the server, except the deprecated `hcl import`.

## Commands

| Command | Description |
|---------|-------------|
| `stategraph hcl addresses` | List the Terraform addresses of the HCL in the current directory |
| `stategraph hcl eval` | Evaluate an HCL expression |
| `stategraph hcl json` | Convert between HCL and JSON |
| `stategraph hcl import` | Deprecated. Import the HCL files of the current directory into an existing state. |

## stategraph hcl addresses

Lists the addresses that the HCL declares, including resources in local modules, module calls, and variables. Run it from your root module.

```bash
stategraph hcl addresses
```

### Example

```bash
cd my-terraform-module
stategraph hcl addresses
```

Output (one address per line):

```text
module.app.aws_instance.web
module.app
aws_subnet.public
aws_vpc.main
var.region
```

Use the list to write address globs for [`--force`](/docs/cli/tf), [`--attach-files`](/docs/cli/import), or [`stategraph config files`](/docs/cli/config), and in scripts.

## stategraph hcl eval

Evaluates an HCL expression and prints the result. Use it to test interpolations and function calls without a plan.

```bash
stategraph hcl eval [-e KEY=EXPR] [<expression>]
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `<expression>` | No | HCL expression to evaluate. Without it, the command reads stdin. |

### Options

| Option | Required | Description |
|--------|----------|-------------|
| `-e KEY=EXPR` | No | Bind a variable. `KEY` is a dot-separated path, for example `var.name`. `EXPR` is an HCL expression, evaluated with the bindings before it. Repeatable. |

### Examples

```bash
# Simple arithmetic
stategraph hcl eval '1 + 2'
# 3

# Terraform functions work
stategraph hcl eval 'upper("hello")'
# HELLO

stategraph hcl eval 'join("-", ["a", "b", "c"])'
# a-b-c

# Bind variables with -e, then reference them
stategraph hcl eval -e 'var.region="us-east-1"' '"bucket-${var.region}"'
# bucket-us-east-1
```

## stategraph hcl json

Reads stdin and writes stdout. By default, it converts HCL to JSON in the Terraform [JSON configuration syntax](https://developer.hashicorp.com/terraform/language/syntax/json).

```bash
stategraph hcl json [--safe] [--to-hcl]
```

### Options

| Option | Required | Description |
|--------|----------|-------------|
| `--to-hcl` | No | Convert JSON to HCL, not HCL to JSON |
| `--safe` | No | Use a schema-free encoding that keeps the block structure, in place of the Terraform JSON syntax |

### Examples

HCL to JSON:

```bash
stategraph hcl json < main.tf
```

```json
{
  "resource": {
    "aws_s3_bucket": {
      "data": [ { "bucket": "my-data", "tags": { "env": "prod" } } ]
    }
  }
}
```

JSON back to HCL:

```bash
stategraph hcl json --to-hcl < main.tf.json
```

```text
resource "aws_s3_bucket" "data" {
  bucket = "my-data"
}
```

With `--safe`, the output is a flat list of blocks with explicit `type`, `labels`, and `attrs`:

```bash
stategraph hcl json --safe < main.tf
```

```json
[
  {
    "type": "resource",
    "labels": [ "aws_s3_bucket", "data" ],
    "attrs": [ { "bucket": "my-data" } ]
  }
]
```

## stategraph hcl import

Deprecated. The command stays only for existing scripts. Use [`stategraph import tf --hcl --overwrite`](/docs/cli/import) instead. It imports the same HCL plus tfvars, files, and revision hashes, and records the current schema version. The resources that the state records do not change.

`hcl import` imports only the HCL blocks of the root module, and does not update the stored schema version of the state. So it cannot bring the configuration of a state to the format that your server version expects.

```bash
stategraph hcl import --tenant <tenant-id> --state <state-id> [options]
```

### Options

| Option | Required | Description |
|--------|----------|-------------|
| `--tenant` | Yes | Tenant ID (UUID), or set `STATEGRAPH_TENANT_ID` |
| `--state` | Yes | State ID (UUID) to import the HCL into |
| `--workspace` | No | Workspace for the state (default: `"default"`), or set `STATEGRAPH_WORKSPACE` |
| `-y` | No | Auto-confirm interactive prompts, or set `STATEGRAPH_NON_INTERACTIVE` |
| `--silent` | No | Suppress prompt output (only with `-y`), or set `STATEGRAPH_SILENT` |

### Example

```bash
cd my-terraform-module
stategraph hcl import \
  --tenant 550e8400-e29b-41d4-a716-446655440000 \
  --state 7c9e6679-7425-40de-944b-e07fc1f90ae7
```

## Debugging: stategraph test tf load

The `stategraph test` group holds debug helpers. `stategraph test tf load` parses a Terraform module directory as an import does. It prints the parsed HCL, with each local module inlined under a `# module <address>` comment. Use it when an import or a plan does not get what you expect.

```bash
stategraph test tf load [--out <file>] <path>
```

| Option | Required | Description |
|--------|----------|-------------|
| `<path>` | Yes | Path to a Terraform module directory |
| `--out` | No | Output file (default: stdout) |

```bash
stategraph test tf load .
```

## Next Steps

- [Import Commands](/docs/cli/import): onboard a state and its HCL in one step.
- [Config Commands](/docs/cli/config): attach data files to addresses.
- [Refactor](/docs/cli/refactor): track HCL refactors with moved blocks.
- [Diagnostics](/docs/cli/diagnostics): trace how a root module evaluates.
