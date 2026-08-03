# GitLab end-to-end test harness

Drives real merge requests through a live GitLab against a live Terrateam
server and asserts the observable outcome: the comment that gets posted, the
commit status that gets set, whether an apply is blocked or allowed, what
lands in the database.

Unit tests cannot catch a regression in the webhook → pipeline → comment loop,
because every interesting part of it is on the other side of GitLab. This is
that other side.

## What it needs

A GitLab (gitlab.com or self-hosted) and a Terrateam server that GitLab can
reach. There is no container for either — pointing the harness at whatever you
already run is the whole idea, and it means the same scenarios validate a
laptop, CI, and a staging deploy.

Running GitLab CE locally alongside the stack is possible but heavy: Omnibus
wants ≥4 GB RAM before a runner, postgres and the Terrateam server are added.
If the host has the memory, set `GITLAB_WEB_BASE_URL`/`GITLAB_API_BASE_URL` at
it and everything else works unchanged.

One constraint is easy to miss: **fixture projects must be created in the group
the Terrateam installation was installed against.** The server acts on a repo
using that installation's access token, so a project in any other group is
invisible to it.

## Setup

```sh
cp env.example .env
$EDITOR .env
./run-scenario --list
```

The installation id and webhook secret come from the Terrateam database:

```sql
select id, webhook_secret from gitlab_installations where name = '<group>';
```

## Running

```sh
./run-scenario 1.1          # one scenario
./run-scenario 3.3 3.4      # several
./run-scenario --all        # the suite (nightly)
```

Exit status is non-zero if any scenario fails. Each scenario creates its own
throwaway project, registers a webhook on it, does its work, and deletes the
project — so scenarios are idempotent, self-cleaning, and safe to run in
sequence unattended. `E2E_KEEP=1` leaves the project behind for debugging.

## Layout

```
harness/
  config.py     environment contract
  gitlab.py     stdlib-only GitLab API client
  fixture.py    the throwaway Terraform project and its lifecycle
  scenario.py   registry, execution context, assertions
  runner.py     CLI
scenarios/
  markers.py    strings asserted on, traced back to the comment templates
  phase1.py     TEST-PLAN Phase 1 (1.1-1.8) -- the core loop
  item03.py     TEST-PLAN 3.3, 3.4
  item04.py     TEST-PLAN 3.8
```

The fixture is three Terraform directories (`dev/`, `prod/`, `modules/shared`)
built entirely from `null_resource`, so no cloud credentials are ever needed,
plus a `.gitlab-ci.yml` declaring the four pipeline inputs Terrateam sends
(`TERRATEAM_TRIGGER`, `WORK_TOKEN`, `API_BASE_URL`, `RUNS_ON`). All four need
defaults or GitLab refuses the trigger and the server reports
`GITLAB_INPUTS_MISSING_DEFAULTS`.

## Writing a scenario

```python
from harness.scenario import scenario
from . import markers

@scenario("5.1", "What this proves", phase=5)
def my_scenario(ctx):
    ctx.fixture.create()
    ctx.fixture.register_webhook()
    branch = ctx.fixture.branch_with_change("e2e/thing", dirs=("dev",))
    mr = ctx.fixture.open_mr(branch)

    ctx.wait_for_note_containing(mr["iid"], markers.PLAN_COMPLETE)
    ctx.comment(mr["iid"], "terrateam apply")
    ctx.wait_for_note_containing(mr["iid"], markers.APPLY_COMPLETE)
```

Add the module to `scenarios/__init__.py` so `--all` picks it up.

Two rules worth keeping:

- **Assert on real API state where you can** — notes, commit statuses,
  `detailed_merge_status`, rows in the database. Log grepping is the fallback
  for the cases where the expected outcome genuinely is "nothing happened and
  nothing crashed" (see `item03.py`).
- **Assert the failure path too.** A scenario that only proves the happy path
  still passes when a check has been removed entirely; `item04.py` asserts the
  rejection *and* that a real run completes, because either half alone can pass
  for the wrong reason.
