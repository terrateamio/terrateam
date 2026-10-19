---
title: stategraph repo-config
description: Print the fully evaluated repository configuration from a pull request comment, with config builder, indexer, and override outputs.
order: 8
---


`stategraph repo-config` is a pull request comment, not a terminal command: it prints the fully evaluated repository configuration. The evaluated configuration is often not the one that you expect.

## Usage

```text
stategraph repo-config
```

Stategraph replies with a **Repository Config** comment. Expand its **Details** block to read the configuration sources and the evaluated YAML. The YAML shows:

- The final merged configuration, with the config builder, indexer, and override outputs applied
- The directories that the indexer discovered
- The evaluated tag queries and workflows
- The resolved environment variables

Include the whole comment when you ask for [support](/docs/support).

## Related commands

- [stategraph plan](/docs/reference/orchestration/commands/plan): run plans with the evaluated configuration
- [stategraph apply](/docs/reference/orchestration/commands/apply): run applies with the evaluated configuration
