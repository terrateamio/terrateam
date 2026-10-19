---
title: Ignoring a Directory
description: Configure .stategraph/config.yml so that changes in specific directories or files never trigger automatic plans and applies.
order: 15
---


To stop Stategraph Orchestration from running plans and applies for a directory or a file, set its `when_modified.file_patterns` in `.stategraph/config.yml`. Use this for:

- Directories with Terraform modules that you do not deploy directly, such as shared modules or templates.
- Supporting files or folders that match Terraform file patterns (like `.tf`) but should not trigger infrastructure changes.

`file_patterns` takes glob patterns, so you can match or exclude files and directories precisely. In `file_patterns`, `${DIR}` is the current directory. See [globs](/docs/reference/orchestration/configuration/dirs#globs) and [when_modified](/docs/reference/orchestration/configuration/dirs#when-modified) in the dirs reference.

## How to Ignore a Directory

Add the directory to the `dirs` section and set `when_modified.file_patterns` to an empty list. For example, to ignore the `docs` directory:

```yaml
dirs:
  docs:
    when_modified:
      file_patterns: []
```

Changes to files in the `docs` directory then trigger no plans or applies.

## Ignoring Module Directories

To stop changes in a module directory, such as `modules/`, from triggering runs directly, ignore the full directory:

```yaml
dirs:
  modules:
    when_modified:
      file_patterns: []
```

## Ignoring Specific Files

Keys of the `dirs` section always name directories. A key that matches a file resolves to the directory that contains the file. `file_patterns: []` under such a key thus disables the full directory, not only the file.

To ignore specific files, keep the directory enabled and exclude the files from `file_patterns` with a `!` pattern. For example, to ignore `foobar/generated.tf` and still plan on the other files in `foobar`:

```yaml
dirs:
  foobar:
    when_modified:
      file_patterns: ["${DIR}/*.tf", "${DIR}/*.tfvars", "!${DIR}/generated.tf"]
```

Exclusions also take glob patterns, such as all `dev.*.tfvars` files in a directory:

```yaml
dirs:
  foobar:
    when_modified:
      file_patterns: ["${DIR}/*.tf", "${DIR}/*.tfvars", "!${DIR}/dev.*.tfvars"]
```

## Advanced: Ignoring by Pattern

A glob pattern as a `dirs` key ignores every directory that matches it. For example, to ignore all directories under `test/`:

```yaml
dirs:
  test/**:
    when_modified:
      file_patterns: []
```

To ignore files that end in `.example.tf` in every directory, set a top-level `when_modified` with an exclusion. The top-level `file_patterns` applies to every directory that does not override it:

```yaml
when_modified:
  file_patterns: ["${DIR}/*.tf", "${DIR}/*.tfvars", "!${DIR}/*.example.tf"]
```

Use precise patterns, so that you do not ignore important infrastructure code by accident.

## Related

- [dirs](/docs/reference/orchestration/configuration/dirs)
- [when_modified](/docs/reference/orchestration/configuration/when-modified)
- [Modules](/docs/orchestration/configuration/modules)
