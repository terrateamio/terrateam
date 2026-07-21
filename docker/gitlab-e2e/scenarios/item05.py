"""Audit item 05 / TEST-PLAN 3.2 -- comment strategies on GitLab.

The GitLab comment layer hardcoded Append and raised nyi from the comment-id
lookups, because it had no table mapping a dirspace back to the note it had
posted.  Every run therefore added another comment.

These scenarios run a plan twice on one merge request and assert what happened
to the *first* note, which is the only way to tell the strategies apart:

- minimize: the first note still exists but its body has been collapsed.  GitLab
  has no native minimize, so Terrateam rewrites the note as a closed <details>
  block wrapping the original body.
- delete: the first note is gone.
- append (the default): the first note is untouched and both remain.
"""

from harness.scenario import scenario

from . import markers

MINIMIZE_MARKER = "Outdated output (minimized)"


def _config(strategy):
    return """\
notifications:
  summary:
    enabled: true
  policies:
    - tag_query: ''
      comment_strategy: %s
when_modified:
  file_patterns:
    - '${DIR}/*.tf'
""" % strategy


def _plan_notes(ctx, iid):
    return [n for n in ctx.notes(iid) if markers.PLAN_COMPLETE in n["body"]]


def _run_twice(ctx, strategy):
    ctx.fixture.create(config_yml=_config(strategy))
    ctx.fixture.register_webhook()
    branch = ctx.fixture.branch_with_change("e2e/comment")
    mr = ctx.fixture.open_mr(branch)

    ctx.wait_for_note_containing(mr["iid"], markers.PLAN_COMPLETE)
    first = _plan_notes(ctx, mr["iid"])[0]
    ctx.log("first plan note is %d" % first["id"])

    ctx.comment(mr["iid"], "terrateam plan")

    def second_plan():
        notes = _plan_notes(ctx, mr["iid"])
        newer = [n for n in notes if n["id"] != first["id"]]
        return newer[0] if newer else None

    second = ctx.wait_for("a second plan comment", second_plan)
    ctx.log("second plan note is %d" % second["id"])
    return mr, first, second


def _note_ids(ctx, iid):
    return {n["id"] for n in ctx.notes(iid)}


@scenario("3.2", "Comment strategy minimize collapses the previous comment", phase=3)
def minimize_strategy(ctx):
    mr, first, _second = _run_twice(ctx, "minimize")

    def collapsed():
        for note in ctx.notes(mr["iid"]):
            if note["id"] == first["id"]:
                return MINIMIZE_MARKER in note["body"] or None
        # The note disappearing is a failure for minimize, not a pass.
        raise AssertionError("the first note was deleted, but the strategy was minimize")

    ctx.wait_for("the first comment to be collapsed", collapsed, timeout=120)


@scenario("3.2d", "Comment strategy delete removes the previous comment", phase=3)
def delete_strategy(ctx):
    mr, first, _second = _run_twice(ctx, "delete")

    def gone():
        return first["id"] not in _note_ids(ctx, mr["iid"]) or None

    ctx.wait_for("the first comment to be deleted", gone, timeout=120)


@scenario("3.2a", "Comment strategy append leaves the previous comment alone", phase=3)
def append_strategy(ctx):
    mr, first, second = _run_twice(ctx, "append")

    ids = _note_ids(ctx, mr["iid"])
    ctx.assert_true(first["id"] in ids, "the first comment is still present")
    ctx.assert_true(second["id"] in ids, "the second comment is present")
    for note in ctx.notes(mr["iid"]):
        if note["id"] == first["id"]:
            ctx.assert_true(
                MINIMIZE_MARKER not in note["body"], "the first comment was not collapsed"
            )
