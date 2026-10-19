---
title: Config Commands
description: Use the stategraph config commands to edit stategraph.json, attach external files to resource addresses per workspace, and mark tfvars as ephemeral.
order: 11
---


The `stategraph config` commands edit the `stategraph.json` file in your module directory: they attach files to addresses and mark tfvars as ephemeral. They run locally and do not contact the server.

## Why attach files

When your HCL reads files with `file()`, `templatefile()`, `fileset()`, `filebase64()`, or `data.local_file`, Stategraph must know which files belong to a change. `stategraph config files` records them as globs in `stategraph.json`, per workspace and address glob. When an attached file changes, the next plan includes the matching resources.

## Commands

| Command | Description |
|---------|-------------|
| `stategraph config files attach` | Attach file globs to an address glob in a workspace |
| `stategraph config files remove` | Remove file globs, or all attachments at an address |
| `stategraph config tfvar ephemeral add` | Mark tfvars as ephemeral, by glob |
| `stategraph config tfvar ephemeral list` | List the ephemeral tfvar globs |
| `stategraph config tfvar ephemeral remove` | Remove ephemeral tfvar globs |

## stategraph config files attach

The address, `--dest`, and `--expr` together identify an attachment:

- The same three values again add the new globs to the existing ones.
- A new `--dest` or `--expr` records a separate attachment at the same address. It does not move the files already attached.

```bash
stategraph config files attach --workspace <workspace> --address <address-glob> [--dest <dest>] [--expr <expr>] [--recursive] <file-glob>...
```

### Options

| Option | Required | Description |
|--------|----------|-------------|
| `--address` | Yes | Address glob of the blocks that get the files, for example `'module.foo.*'`. Same glob grammar as `--force`. |
| `--workspace` | Yes | Workspace whose config entry to change |
| `--dest` | No | Destination directory for the files. Default: the bundle root. |
| `--expr` | No | The exact HCL expression that the files are for. Default: the whole block. |
| `-r`, `--recursive` | No | Treat the arguments as paths, not globs, and keep the directory shape. |

`--dest` supports `${path.module}` (the module directory of the matched block) and `${path.root}` (the bundle root), each with an optional relative subdirectory, for example `'${path.module}/config'`.

Use `--expr` when a block has more than one file call, for example `--expr 'fileset(path.module, "**/*.yaml")'`. `--address` selects only the block. The next plan or import matches the expression:

- Matching is structural. Formatting and whitespace do not matter, but the function and its arguments must be the same.
- If no block that the address matches contains the expression, the plan or import fails.

With `--recursive`:

- A directory gives its contents. Its own name is dropped, and each file keeps its path relative to that directory, under `--dest`.
- A file gives itself, at its basename.
- A path that does not exist, an argument with a glob metacharacter, or two paths that give the same destination file is an error.

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `<file-glob>...` | Yes | One or more file globs to attach at the address. With `--recursive`, paths to a file or directory. |

### Example

```bash
stategraph config files attach --workspace default --address 'module.app.*' './templates/*.tpl'
```

```text
Attached 1 glob(s) at module.app.* for workspace default
```

The resulting entry in `stategraph.json`:

```json
{
  "workspaces": {
    "default": {
      "attached_files": [
        {
          "address_glob": "module.app.*",
          "globs": [ "./templates/*.tpl" ],
          "dest": null,
          "recursive": false,
          "expr": null
        }
      ]
    }
  }
}
```

To attach a directory tree under the module directory, use `--recursive` and `--dest`:

```bash
stategraph config files attach --workspace default --address 'module.app.*' --dest '${path.module}/config' --recursive ./config
```

```text
Attached 1 path(s) at module.app.* for workspace default
```

Commit `stategraph.json`, so that the mappings travel with the module.

## stategraph config files remove

An address can hold several attachments, and the command applies to all of them:

- It removes each named glob wherever it occurs at the address. An attachment left with no globs is removed.
- With no globs, it removes every attachment at the address.
- To remove only one of several attachments, edit `stategraph.json`.

```bash
stategraph config files remove --workspace <workspace> --address <address-glob> [<file-glob>...]
```

### Options

| Option | Required | Description |
|--------|----------|-------------|
| `--address` | Yes | Address glob to change |
| `--workspace` | Yes | Workspace whose config entry to change |

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `<file-glob>...` | No | File globs to remove |

### Examples

```bash
# Remove one glob
stategraph config files remove --workspace default --address 'module.app.*' './templates/*.tpl'

# Remove every attachment at the address
stategraph config files remove --workspace default --address 'module.app.*'
```

## stategraph config tfvar ephemeral

An ephemeral tfvar changes at each run but changes nothing, for example a per-run authentication token. Stategraph passes it to the run, but:

- never uses it to create the subgraph,
- never stores it in the database,
- masks its value in the SQL interface.

The globs apply to every workspace.

### stategraph config tfvar ephemeral add

```bash
stategraph config tfvar ephemeral add <glob>...
```

| Argument | Required | Description |
|----------|----------|-------------|
| `<glob>...` | Yes | One or more globs that name tfvars to treat as ephemeral |

The globs use the `--force` grammar: `*` matches any sequence of characters, every other character is literal, and a glob must match the whole name.

```bash
stategraph config tfvar ephemeral add 'auth_token' '*_session_token'
```

### stategraph config tfvar ephemeral list

Accepts `--format` (`table`, `json`, or `simple`).

```bash
stategraph config tfvar ephemeral list
```

### stategraph config tfvar ephemeral remove

```bash
stategraph config tfvar ephemeral remove <glob>...
```

| Argument | Required | Description |
|----------|----------|-------------|
| `<glob>...` | Yes | One or more ephemeral tfvar globs to remove |

Each glob is compared with the configured globs as a literal string, not as a pattern. Spell it exactly as `config tfvar ephemeral list` prints it: removing `'*_token'` does not remove a configured `'auth_token'`. If one of the globs is not configured, the command removes nothing and exits non-zero.

```bash
stategraph config tfvar ephemeral remove '*_session_token'
```

## Next steps

- [Import Commands](/docs/cli/import): `stategraph import tf --attach-files` sets the same mappings at import time, and `--attach-dest` sets the destination directory as `--dest` does.
- [Terraform Commands](/docs/cli/tf): attached files in plans.
- [HCL Commands](/docs/cli/hcl): list addresses for globs.
