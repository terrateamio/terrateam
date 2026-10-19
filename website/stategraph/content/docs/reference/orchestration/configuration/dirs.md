---
title: dirs
description: Reference for the dirs key in .stategraph/config.yml. Assign tags, workspaces, and when_modified rules to directories, with glob matching.
order: 10
---


`dirs` sets the [tags](/docs/reference/orchestration/configuration/tag-queries), workspaces, and [when modified](/docs/reference/orchestration/configuration/when-modified) rules of each directory in your repository. A directory key can also be a glob that matches many directories.

## Default Configuration

```yaml
dirs: {}
```

## Keys

Each key of `dirs` is a directory path, and each value is a map with these keys:

| Key | Type | Description |
| --- | --- | --- |
| `create_and_select_workspace` | boolean | `true`: Orchestration selects the workspace, and creates it if it does not exist. Only the `terraform`, `tofu`, and `terragrunt` engines use it. Default is `true`. |
| `create_if_missing` | boolean | `true`: Orchestration creates the directory before the workflow steps if it does not exist. Default is `false`. See [Create If Missing](#create-if-missing). |
| `lock_branch_target` | string | With `destination_branches`, sets whether the directory locks per destination branch or across all branches. `all`: two pull requests that change the same workspace have conflicting locks, whatever their destination branch. `dest_branch`: only pull requests that change the same workspace and target the same destination branch conflict. Default is `all`. |
| `tags` | list | The tags of the directory. A [tag query](/docs/reference/orchestration/configuration/tag-queries) selects directories by tag, for example to run a workflow. |
| `workspaces` | object | The workspaces of the directory. See [Workspaces](#workspaces). |
| `stacks` | object | The stacks of the directory, for the [CDKTF](/docs/orchestration/iac-tools/cdktf) engine. The key is the stack name, and the value takes `tags` and `when_modified`, as in `workspaces`. |
| `when_modified` | object | Which file changes in a pull request autoplan and autoapply the directory. See [When Modified](#when-modified). |

## Example Configuration

```yaml
dirs:
  ec2:
    tags: [aws, ec2]
    workspaces:
      production:
        tags: [production]
    when_modified:
      file_patterns: ["ec2/*.tf", "ec2/*.tfvars", "iam/*.tf", "iam/*.tfvars"]
  iam:
    tags: [aws, iam]
```

## Directory Configuration

### Create If Missing

Use `create_if_missing` for directories that a tool generates at run time. For example, the [config builder](/docs/orchestration/workflows/advanced/terragrunt-config-builder) can register directories that `terragrunt stack generate` makes. Orchestration creates the directory before any workflow step, such as init, plan, or apply.

```yaml
dirs:
  generated/stacks/vpc:
    create_if_missing: true
    tags: [vpc]
```

In the config builder output, set `create_if_missing: true` on each directory that is generated at run time:

```json
{
  "dirs": {
    "generated/stacks/vpc": {
      "create_if_missing": true,
      "tags": ["vpc"]
    }
  }
}
```

### Tags

Each directory and workspace also gets implicit tags:

- `dir:<name>`: `<name>` is the path of the directory, with no trailing `/`.
- `workspace:<name>`: `<name>` is the name of the workspace.

### Workspaces

`workspaces` is an object. Each key is a workspace name, and each value takes these keys:

| Key | Type | Description |
| --- | --- | --- |
| `tags` | list | The tags of the workspace, to target operations on it. |
| `when_modified` | object | The `when_modified` rules of the workspace. They override the directory and global rules. |

#### Example

```yaml
dirs:
  infrastructure:
    tags: [aws]
    workspaces:
      production:
        tags: [critical, prod]
        when_modified:
          file_patterns: ["${DIR}/*.tf", "shared/*.tf", "modules/*.tf"]
          autoplan: true
          autoapply: true
      staging:
        tags: [non-critical, staging]
        when_modified:
          file_patterns: ["${DIR}/*.tf", "shared/*.tf"]
          autoplan: true
          autoapply: false
```

The directory tag `aws` applies to both workspaces. Each workspace adds its own tags and `when_modified` rules.

### When Modified

`when_modified` has the same syntax at three levels:

- Global: the top-level `when_modified` key.
- Directory: `dirs.<directory>.when_modified`, for all workspaces of the directory.
- Workspace: `dirs.<directory>.workspaces.<workspace>.when_modified`, for that workspace only.

A more specific level overrides a broader one, key by key. For example, set only `autoapply: true` for a workspace, and the other keys come from the directory or global level.

- Without `file_patterns`, a directory uses the global value. Its default is `["${DIR}/*.tf", "${DIR}/*.tfvars"]`.
- `file_patterns` are relative to the root of the repository.
- `${DIR}` in `file_patterns` is the directory that Orchestration works on, relative to the root of the repository.

#### Examples

##### Directory-Level Configuration

This plans the directory when a pull request changes `foobar/*.tf`:

```yaml
dirs:
  foobar:
    when_modified:
      file_patterns: ["${DIR}/*.tf"]
```

##### Workspace-Level Configuration

Here, `production` autoplans and autoapplies when the directory files or the shared files change. `staging` only autoplans.

```yaml
dirs:
  foobar:
    workspaces:
      production:
        when_modified:
          file_patterns: ["${DIR}/*.tf", "shared/*.tf"]
          autoplan: true
          autoapply: true
      staging:
        when_modified:
          file_patterns: ["${DIR}/*.tf"]
          autoplan: true
          autoapply: false
```

## Globs

A `dirs` key can be a glob. Use globs when many directories share a configuration.

### Example

A repository has these files:

- `_templates/ec2/terragrunt.hcl`
- `prod/ec2/us-east-1/foo.tf`
- `prod/ec2/us-west-1/foo.tf`
- `prod/ebs/us-east-1/foo.tf`
- `prod/ebs/us-west-1/foo.tf`
- `.stategraph/config.yml`:

```yaml
dirs:
  _templates/**:
    when_modified:
      file_patterns: []
  prod/**/ec2/**:
    tags: [prod, ec2]
    when_modified:
      file_patterns: ["_templates/**/*.tf", "${DIR}/*.tf"]
  prod/**:
    tags: [prod]
    when_modified:
      file_patterns: ["_templates/**/*.tf", "${DIR}/*.tf"]
```

For each operation, Orchestration expands the globs against the files into this `dirs` configuration:

```yaml
dirs:
  _templates/ec2:
    when_modified:
      file_patterns: []
  prod/ec2/us-east-1:
    tags: [prod, ec2]
    when_modified:
      file_patterns: ["_templates/**/*.tf", "prod/ec2/us-east-1/*.tf"]
  prod/ec2/us-west-1:
    tags: [prod, ec2]
    when_modified:
      file_patterns: ["_templates/**/*.tf", "prod/ec2/us-west-1/*.tf"]
  prod/ebs/us-east-1:
    tags: [prod]
    when_modified:
      file_patterns: ["_templates/**/*.tf", "prod/ebs/us-east-1/*.tf"]
  prod/ebs/us-west-1:
    tags: [prod]
    when_modified:
      file_patterns: ["_templates/**/*.tf", "prod/ebs/us-west-1/*.tf"]
```

### Longest Glob Match

When more than one glob matches a directory, the longest glob wins, because it is the most specific. In the example above, the files in `prod/ec2` match `prod/**/ec2/**` and `prod/**`. The directories get the configuration of `prod/**/ec2/**`.

### Directory Globs Match Files (Terragrunt)

A glob can reach the file level. Orchestration then uses the directory of the file as the `dirs` entry. For example, for a Terragrunt repository:

```yaml
dirs:
  _templates/**/terragrunt.hcl:
    when_modified:
      file_patterns: []
  "**/terragrunt.hcl":
    tags: [terragrunt]
    when_modified:
      file_patterns: ['_templates/**/terragrunt.hcl', '${DIR}/*.hcl', '${DIR}/*.tf', '${DIR}/*.tfvars']
```

- The first entry turns off operations in each directory under `_templates/` with a `terragrunt.hcl` file.
- The second entry runs operations on a directory with a `terragrunt.hcl` file when the pull request changes an `hcl`, `tf`, or `tfvars` file in it, or a `terragrunt.hcl` file under `_templates/`.

## Related

- [when_modified](/docs/reference/orchestration/configuration/when-modified)
- [Ignoring a directory](/docs/reference/orchestration/configuration/ignore-patterns)
- [Tag queries](/docs/reference/orchestration/configuration/tag-queries)
- [Tag system](/docs/orchestration/workflows/advanced/tag-system)
