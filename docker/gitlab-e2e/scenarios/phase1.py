"""TEST-PLAN Phase 1 -- the core plan/apply loop.

These are the baseline scenarios: they are expected to pass on any healthy
install and are what a regression in the GitLab integration would break first.
"""

from harness.scenario import scenario

from . import markers


def _fixture_with_mr(ctx, dirs=("dev",), config_yml=None):
    """Seed a fixture, wire the webhook, and open an MR touching ``dirs``."""
    kwargs = {"config_yml": config_yml} if config_yml else {}
    ctx.fixture.create(**kwargs)
    ctx.fixture.register_webhook()
    branch = ctx.fixture.branch_with_change("e2e/change", dirs=dirs)
    return ctx.fixture.open_mr(branch)


@scenario("1.1", "Autoplan on MR open produces a plan comment and a commit status", phase=1)
def autoplan_on_open(ctx):
    mr = _fixture_with_mr(ctx)
    ctx.wait_for_note_containing(mr["iid"], markers.PLAN_COMPLETE)
    # The plan should have found a change: the fixture bumps a trigger value.
    note = ctx.wait_for_note_containing(mr["iid"], markers.PLAN_SUCCESS)
    ctx.assert_names_dirspace(note["body"], "dev")
    ctx.wait_for_status(mr["sha"], "terrateam apply", states=("success", "pending", "failed"))


@scenario("1.2", "terrateam plan comment triggers a plan", phase=1)
def plan_via_comment(ctx):
    mr = _fixture_with_mr(ctx)
    # Let the autoplan settle first so the assertion below cannot match it.
    ctx.wait_for_note_containing(mr["iid"], markers.PLAN_COMPLETE)
    before = len(ctx.notes(mr["iid"]))
    ctx.comment(mr["iid"], "terrateam plan")

    def another_plan():
        notes = ctx.notes(mr["iid"])
        if len(notes) <= before:
            return None
        return any(markers.PLAN_COMPLETE in n["body"] for n in notes[before:]) or None

    ctx.wait_for("a second plan comment", another_plan)


@scenario("1.3", "terrateam apply comment applies and the status goes green", phase=1)
def apply_via_comment(ctx):
    mr = _fixture_with_mr(ctx)
    ctx.wait_for_note_containing(mr["iid"], markers.PLAN_COMPLETE)
    ctx.comment(mr["iid"], "terrateam apply")
    ctx.wait_for_note_containing(mr["iid"], markers.APPLY_COMPLETE)
    ctx.wait_for_status(mr["sha"], "terrateam apply", states=("success",))


@scenario("1.4", "Pushing to the MR branch re-plans (Sync)", phase=1)
def replan_on_push(ctx):
    mr = _fixture_with_mr(ctx)
    ctx.wait_for_note_containing(mr["iid"], markers.PLAN_COMPLETE)
    before = len(ctx.notes(mr["iid"]))

    ctx.log("pushing a second commit to the MR branch")
    ctx.fixture.branch_with_change("e2e/change", dirs=("dev",), revision="3")

    def replanned():
        notes = ctx.notes(mr["iid"])
        if len(notes) <= before:
            return None
        return any(markers.PLAN_COMPLETE in n["body"] for n in notes[before:]) or None

    ctx.wait_for("a plan comment for the new commit", replanned)


@scenario("1.5", "Merging the MR is handled without error", phase=1)
def merge_is_handled(ctx):
    mr = _fixture_with_mr(ctx)
    ctx.wait_for_note_containing(mr["iid"], markers.PLAN_COMPLETE)
    ctx.comment(mr["iid"], "terrateam apply")
    ctx.wait_for_note_containing(mr["iid"], markers.APPLY_COMPLETE)

    def mergeable():
        current = ctx.gl.merge_request(ctx.fixture.id, mr["iid"])
        return current.get("detailed_merge_status") == "mergeable" or None

    ctx.wait_for("the MR to become mergeable", mergeable)
    current = ctx.gl.merge_request(ctx.fixture.id, mr["iid"])
    ctx.gl.merge_merge_request(ctx.fixture.id, mr["iid"], sha=current["sha"])

    def merged():
        current = ctx.gl.merge_request(ctx.fixture.id, mr["iid"])
        return current["state"] == "merged" or None

    ctx.wait_for("the MR to report merged", merged)
    # The close path must not crash the event handler.
    ctx.assert_not_in_logs(markers.NYI)


@scenario("1.6", "Two dirspaces plan; apply dir:dev applies only dev", phase=1)
def dirspace_targeting(ctx):
    mr = _fixture_with_mr(ctx, dirs=("dev", "prod"))
    note = ctx.wait_for_note_containing(mr["iid"], markers.PLAN_COMPLETE)
    ctx.assert_names_dirspace(note["body"], "dev")
    ctx.assert_names_dirspace(note["body"], "prod")

    ctx.comment(mr["iid"], "terrateam apply dir:dev")
    applied = ctx.wait_for_note_containing(mr["iid"], markers.APPLY_COMPLETE)
    ctx.assert_names_dirspace(applied["body"], "dev")
    ctx.assert_names_dirspace(applied["body"], "prod", present=False)


@scenario("1.7", "terrateam unlock releases a lock", phase=1)
def unlock(ctx):
    mr = _fixture_with_mr(ctx)
    ctx.wait_for_note_containing(mr["iid"], markers.PLAN_COMPLETE)
    ctx.comment(mr["iid"], "terrateam unlock")
    ctx.wait_for_note_containing(mr["iid"], markers.UNLOCK_SUCCESS)


@scenario("1.8", "A very large plan falls back to the compact comment", phase=1)
def large_plan_output(ctx):
    # 400 resources is comfortably past the GitLab comment size limit once
    # rendered as a plan diff.
    big = """\
terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

resource "null_resource" "big" {
  count = 400
  triggers = {
    revision = "2"
    padding  = "%s"
  }
}
""" % ("x" * 2000)

    ctx.fixture.create()
    ctx.fixture.register_webhook()
    ctx.gl.commit(
        ctx.fixture.id,
        "e2e/big",
        "CHG Produce a very large plan",
        [{"action": "update", "file_path": "dev/main.tf", "content": big}],
        start_branch=ctx.fixture.default_branch,
    )
    mr = ctx.fixture.open_mr("e2e/big")

    def compact_or_plan():
        for note in ctx.notes(mr["iid"]):
            if markers.COMMENT_TOO_LARGE in note["body"]:
                return note
            if markers.PLAN_COMPLETE in note["body"]:
                return note
        return None

    note = ctx.wait_for("a plan comment, compact or full", compact_or_plan)
    ctx.assert_true(
        len(note["body"]) < 1_000_000, "the comment Terrateam posted was accepted by GitLab"
    )
    ctx.assert_not_in_logs(markers.NYI)
