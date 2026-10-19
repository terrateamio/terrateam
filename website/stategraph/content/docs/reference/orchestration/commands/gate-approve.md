---
title: stategraph gate approve
description: Approve failed Gatekeeper gates by their tokens from a pull request comment, so that the apply can proceed.
order: 7
---


`stategraph gate approve` is a pull request comment, not a terminal command: it approves [Gatekeeper](/docs/orchestration/governance/gatekeeper) gates, so that the apply can proceed. When a workflow step with a [gate](/docs/reference/orchestration/configuration/workflows#gate) fails, for example a security scan, a policy check, or a custom validation, Stategraph records the gate and blocks the apply until users who match the `all_of` or `any_of` list of the gate approve it.

## Usage

```text
stategraph gate approve <token> [<token> ...]
```

`<token>` is the unique token of a gate, from the gate failure message. One comment can approve several tokens. To approve a gate without a token, approve the pull request.

## Security considerations

!!! warning "Gate approvals bypass failed checks"
    A gate approval lets the apply proceed past a failed validation. Give approval permission only to trusted users and teams, and keep an audit trail of every approval.

- Use descriptive tokens that show what each approval is for.
- For critical workflows, consider requiring several approvers.

## Related commands

- [stategraph apply-force](/docs/reference/orchestration/commands/apply-force): apply without meeting the apply requirements
