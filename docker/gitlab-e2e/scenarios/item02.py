"""Audit item 02 / TEST-PLAN 3.1 -- gates on GitLab EE.

GitLab EE re-exported the OSS Gate stub, so `add_approval` always returned
`Premium_feature_err Gatekeeping` and `eval` always returned no gates:
gatekeeping was silently inert on GitLab even on a commercial plan.

Two config notes that cost time to work out, recorded here so the next person
does not repeat them:

- A `run` step declares a gate through `on_error`, not through a `gate:` key.
  The strict schema rejects `gate:` on a `run` step; only `checkov`, `conftest`
  and `opa` steps take one.  The published docs are wrong about this.
- The gate is emitted when the step *fails*, which is why the fixture runs
  `false`.  terrat_runner sets `ignore_errors` automatically when a step
  carries gates, so the run still succeeds overall and the gate is what blocks
  the apply.

This scenario needs an **EE** server.  On OSS the apply is refused with the
premium-feature message instead, which the scenario reports as a skip rather
than a failure.
"""

from harness.scenario import Skipped, scenario

from . import markers

GATE_TOKEN = "e2e-gate"

GATE_CONFIG = """\
notifications:
  summary:
    enabled: true
when_modified:
  file_patterns:
    - '${DIR}/*.tf'
workflows:
  - tag_query: ''
    plan:
      - type: init
      - type: plan
      - type: run
        cmd: ['false']
        on_error:
          - type: gate
            token: %s
            any_of: ['*']
            any_of_count: 1
""" % GATE_TOKEN


@scenario("3.1", "Gates block an apply until the token is approved (EE)", phase=3)
def gates_block_apply(ctx):
    ctx.fixture.create(config_yml=GATE_CONFIG)
    ctx.fixture.register_webhook()
    branch = ctx.fixture.branch_with_change("e2e/gate")
    mr = ctx.fixture.open_mr(branch)

    ctx.wait_for_note_containing(mr["iid"], markers.PLAN_COMPLETE)

    # The gate should have been stored from the plan result.
    def gate_stored():
        rows = ctx.psql(
            "select token from gitlab_gates where repository = %d and pull_number = %d"
            % (ctx.fixture.id, mr["iid"])
        )
        return rows or None

    ctx.wait_for("the gate to be recorded in gitlab_gates", gate_stored)

    # --- the apply must be blocked -------------------------------------
    ctx.comment(mr["iid"], "terrateam apply")

    def blocked_or_premium():
        for note in ctx.notes(mr["iid"]):
            if markers.GATE_PREMIUM in note["body"]:
                raise Skipped("server is OSS, gatekeeping is a commercial feature")
            if markers.GATE_BLOCKED in note["body"]:
                return note
        return None

    note = ctx.wait_for("the apply to be blocked by the gate", blocked_or_premium)
    ctx.assert_true(GATE_TOKEN in note["body"], "the blocking comment names the gate token")
    ctx.assert_no_note_containing(mr["iid"], markers.APPLY_COMPLETE)

    # --- approving the gate unblocks it --------------------------------
    ctx.comment(mr["iid"], "terrateam gate approve %s" % GATE_TOKEN)

    def approval_recorded():
        rows = ctx.psql(
            "select approver from gitlab_gate_approvals where token = '%s' "
            "and repository = %d and pull_number = %d" % (GATE_TOKEN, ctx.fixture.id, mr["iid"])
        )
        return rows or None

    ctx.wait_for("the approval to be recorded in gitlab_gate_approvals", approval_recorded)

    ctx.comment(mr["iid"], "terrateam apply")
    ctx.wait_for_note_containing(mr["iid"], markers.APPLY_COMPLETE)
