---
title: Resource-Level Locking
description: Stategraph detects conflicts per resource, not per state, so concurrent transactions on one Terraform state stay safe.
order: 4
---


Stategraph detects conflicts per resource at commit time, and does not lock the full state. Two transactions conflict only when they change overlapping resources. Transactions that do not overlap run in parallel through the full lifecycle:

- Several transactions can plan against one state at the same time.
- Transactions on different resources apply at the same time, in the same state or not.
- Conflict detection works across state boundaries for [multi-state transactions](/docs/infrastructure-as-a-database/multi-state).

## Conflict detection

At commit time, a transaction conflicts with another transaction that touches overlapping resources and:

- Is committing now, or
- Committed after the current transaction was created.

Transactions that only share a read-only dependency, a resource that each one depends on and neither changes, do not conflict.

## Conflict handling

On a conflict, the server rejects the commit with HTTP 409 and gives the IDs of the conflicting transactions. Run `stategraph tf plan` again for the latest state, then apply again.

## Next steps

- [Transactions](/docs/infrastructure-as-a-database/transactions): the lifecycle around the conflict check.
- [Use with Orchestration](/docs/infrastructure-as-a-database/orchestration): conflict checks and the Stategraph Orchestration locks on pull requests.
