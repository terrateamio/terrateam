---
title: stategraph feedback
description: Record feedback, an issue report, or a suggestion from a pull request comment, and find the other support channels.
order: 9
---


`stategraph feedback` is a pull request comment, not a terminal command: it writes your message to the Stategraph server log, with the repository and pull request. It posts no reply. On Stategraph Cloud, the message reaches the Stategraph team. On a self-hosted server, use the other [support channels](/docs/support).

## Usage

```text
stategraph feedback <message>
```

## What to include

- Issue reports: error messages, the affected directories, and reproduction steps
- Feature requests: the use case and the expected behavior
- Questions: context about your setup and what you are trying to achieve

## Related commands

- [stategraph help](/docs/reference/orchestration/commands/help): list the available commands
- [stategraph repo-config](/docs/reference/orchestration/commands/repo-config): the evaluated configuration to attach to a report
