---
title: stategraph help
description: Stategraph Orchestration takes its commands from pull request comments, and stategraph help lists each command with its basic usage.
order: 1
---


Stategraph Orchestration takes its commands from comments on a pull request, not from a terminal. `stategraph help` lists the commands and their basic usage in a reply on the pull request.

- A command is a comment of the form `stategraph <command>`. `terrateam <command>` is a legacy alias for every command.
- GitHub and GitLab accept the same commands.
- Backticks around the command are ignored, so `` `stategraph plan` `` pasted as inline code still runs.
- Only new comments run commands. Editing a comment does not.
- On GitHub, a comment with an unknown command gets a reply with the list of commands.

## Usage

```text
stategraph help
```

## Commands

| Command | Description |
|---------|-------------|
| [`stategraph plan [tag-query]`](/docs/reference/orchestration/commands/plan) | Plan the changed directories, or those matching a tag query |
| [`stategraph apply [tag-query]`](/docs/reference/orchestration/commands/apply) | Apply the stored plans |
| [`stategraph apply-autoapprove [tag-query]`](/docs/reference/orchestration/commands/apply-autoapprove) | Reserved. Orchestration does not run it. |
| [`stategraph apply-force [tag-query]`](/docs/reference/orchestration/commands/apply-force) | Apply without meeting the apply requirements |
| [`stategraph unlock [pr-number...] [drift]`](/docs/reference/orchestration/commands/unlock) | Release the locks a pull request or drift run holds |
| [`stategraph gate approve <token>...`](/docs/reference/orchestration/commands/gate-approve) | Approve a gated workflow step |
| [`stategraph repo-config`](/docs/reference/orchestration/commands/repo-config) | Print the evaluated repository configuration |
| [`stategraph feedback <message>`](/docs/reference/orchestration/commands/feedback) | Record feedback in the server log |

## Related

- [Pull request workflow](/docs/orchestration/workflows): how a pull request moves from plan to apply
- [Tag queries](/docs/reference/orchestration/configuration/tag-queries): the filter syntax that `plan` and `apply` accept
