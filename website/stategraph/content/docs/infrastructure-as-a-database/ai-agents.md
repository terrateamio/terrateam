---
title: AI Agents
description: Use AI agents with Stategraph: six SKILL.md files cover query, change, import, refactor, cost, and routing.
order: 1
---


The Stategraph skills in [github.com/stategraph/skills](https://github.com/stategraph/skills) let AI agents drive the `stategraph` CLI: Claude Code, agents that use [skills.sh](https://skills.sh), or any tool that loads `SKILL.md` files. The skills teach the workflows, the safe defaults, and the canonical command form. An agent can do everything that [Infrastructure as a Database](/docs/infrastructure-as-a-database) exposes.

## Available skills

| Skill | Purpose |
| --- | --- |
| `stategraph` | Router. Detects Stategraph tasks and dispatches each to one of the five workflow skills below. |
| `stategraph-query` | Read-only SQL queries, state summaries, inventory, blast radius, and gap analysis. |
| `stategraph-cost` | State and tenant cost, attribution by tag or provider, cost history, coverage gaps, and plan-time cost deltas. |
| `stategraph-change` | `stategraph tf plan`, `stategraph tf apply`, state deletion, and the transaction lifecycle. |
| `stategraph-import` | Import `.tfstate` or HCL, and wire a Terraform repository to Stategraph. |
| `stategraph-refactor` | Interactive address rewrites: restructure a repository and keep state addresses. |

Most users need only the `stategraph` router, which hands off through the agent's Skill tool.

## Before you begin

- The Stategraph CLI on your `PATH`. See [CLI reference](/docs/cli).
- A configured tenant: `STATEGRAPH_API_BASE`, `STATEGRAPH_API_KEY`, and `STATEGRAPH_TENANT_ID` exported, and `stategraph info` succeeds. See [Setup](/docs/infrastructure-as-a-database/setup).

## Install

Install the skills with the [skills CLI](https://skills.sh):

```bash
npx skills add stategraph/skills
```

Or install one skill:

```bash
npx skills add stategraph/skills -s stategraph-query
```

### Manual install (Claude Code)

Copy each skill to `~/.claude/skills/<name>/SKILL.md`:

```bash
git clone https://github.com/stategraph/skills /tmp/stategraph-skills
cp -r /tmp/stategraph-skills/skills/* ~/.claude/skills/
rm -rf /tmp/stategraph-skills
```

## Usage

Ask the agent a Stategraph question, and the router picks the workflow:

- "What S3 buckets do we have?" runs `stategraph-query`
- "How much does this tenant cost, broken down by team?" runs `stategraph-cost`
- "Plan these changes." runs `stategraph-change`
- "Import this terraform.tfstate." runs `stategraph-import`
- "Refactor this repo into child modules without losing state." runs `stategraph-refactor`

With all six skills installed, you can also start a workflow directly: `/stategraph-query`, `/stategraph-cost`, `/stategraph-change`, `/stategraph-import`, or `/stategraph-refactor`.

## Safety model

- `stategraph-query` and `stategraph-cost` are read-only. They never call `tf plan`, `tf apply`, imports, or refactors. The only write, in `stategraph-cost`, starts a cost recalculation, not an infrastructure change.
- The change, import, and refactor skills make changes, each in its own workflow.
- With a plan-only API token, the worst result of an agent error is a wrong plan that you discard, not a destroyed database. Use plan-only tokens for agents that run without review, such as overnight runs.
- Give plan and apply rights to agents behind a review step, such as a CI runner on a green pull request.

Create a plan-only token from an existing API key:

```bash
stategraph user access-tokens create --name agent-plan --plan
```

Scope it further with `--plan-tenant`, `--plan-modified`, and `--plan-pulled-in`. See [Access tokens](/docs/admin/access-control/access-tokens) for the capability model, and [Access control](/docs/admin/access-control) for authentication.

## See also

- [github.com/stategraph/skills](https://github.com/stategraph/skills): each skill's full `SKILL.md`.
- [Refactoring](/docs/infrastructure-as-a-database/refactoring): the workflow that the refactor skill drives.
- [Refactor commands](/docs/cli/refactor): its CLI reference.
- [CLI reference](/docs/cli): `stategraph info`, the first command agents run.
