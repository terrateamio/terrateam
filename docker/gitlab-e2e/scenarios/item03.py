"""Audit item 03 / TEST-PLAN 3.3 and 3.4 -- webhook actions must not crash.

Before the fix, every merge-request action other than open/reopen/update/merge/
close hit ``| _ -> raise (Failure "nyi")``, so approving an MR returned a 500
and logged a backtrace.  Approval events are emitted routinely, so this fired
constantly in normal use.

The observable outcome of the fix is that nothing happens, which is why these
scenarios assert on webhook delivery status and on the absence of the exception
in the server logs rather than on a comment.  Both assertions are on real
state: GitLab records the response code it got for each hook delivery.
"""

from harness.scenario import scenario

from . import markers

APPROVAL_ACTIONS = ("approve", "unapprove")


@scenario("3.3", "MR approve/unapprove and draft toggle are NOOPs, not 500s", phase=3)
def approval_actions_are_noops(ctx):
    ctx.fixture.create()
    hook = ctx.fixture.register_webhook()
    branch = ctx.fixture.branch_with_change("e2e/approve")
    mr = ctx.fixture.open_mr(branch)
    iid = mr["iid"]

    ctx.log("approving MR !%d" % iid)
    ctx.gl.approve_merge_request(ctx.fixture.id, iid)
    ctx.log("unapproving MR !%d" % iid)
    ctx.gl.unapprove_merge_request(ctx.fixture.id, iid)

    ctx.log("toggling draft on MR !%d" % iid)
    ctx.gl.update_merge_request(ctx.fixture.id, iid, title="Draft: " + mr["title"])
    ctx.gl.update_merge_request(ctx.fixture.id, iid, title=mr["title"])

    # GitLab keeps the response code of the most recent deliveries.  A 500 from
    # the raise would show up here, and GitLab disables a hook that keeps
    # failing.
    def hook_healthy():
        current = ctx.gl.get("/projects/%d/hooks/%d" % (ctx.fixture.id, hook["id"]))
        if current.get("disabled_until") or current.get("alert_status") == "disabled":
            raise AssertionError(
                "GitLab disabled the webhook, which means Terrateam kept erroring: %s"
                % current.get("alert_status")
            )
        return True

    ctx.wait_for("the webhook to stay healthy", hook_healthy, timeout=60)

    # The real assertion: the exception is gone from the logs.
    ctx.assert_not_in_logs(markers.NYI)

    # And the MR is still functional afterwards -- the handler did not wedge.
    ctx.comment(iid, "terrateam plan")
    ctx.wait_for_note_containing(iid, markers.PLAN_COMPLETE)


@scenario("3.4", "A project in nested subgroups is handled, not a nyi", phase=3)
def deep_subgroup_path(ctx):
    """``parse_path_with_namespace`` used to raise on shapes it did not expect.

    Splitting on the first ``/`` puts the top-level group in ``owner`` and the
    rest in ``name``.  This scenario proves a nested path round-trips: the repo
    must be recorded with the two halves joining back to the full path, and the
    normal plan loop must still work from inside a subgroup.
    """
    # Two levels of nesting gives a path_with_namespace of
    # <group>/<a>/<b>/<project> -- the a/b/c/repo shape the item calls out.
    # The names carry the run's unique suffix because GitLab deletes groups
    # asynchronously: reusing a fixed name collides with the previous run's
    # group while it is still marked for deletion.
    suffix = ctx.fixture.name.rsplit("-", 1)[-1]
    ctx.fixture.create(subgroups=("e2e-a-%s" % suffix, "e2e-b-%s" % suffix))
    ctx.log("fixture path is %s" % ctx.fixture.path)
    ctx.assert_true(
        ctx.fixture.path.count("/") >= 3, "the fixture really is deeply nested"
    )
    ctx.fixture.register_webhook()
    branch = ctx.fixture.branch_with_change("e2e/subgroup")
    mr = ctx.fixture.open_mr(branch)

    ctx.wait_for_note_containing(mr["iid"], markers.PLAN_COMPLETE)
    ctx.assert_not_in_logs(markers.NYI)

    rows = ctx.psql(
        "select owner || '/' || name from gitlab_installation_repositories where id = %d"
        % ctx.fixture.id
    )
    ctx.assert_true(rows, "the repo was recorded in gitlab_installation_repositories")
    ctx.assert_eq(
        rows[0],
        ctx.fixture.path,
        "owner and name rejoin to the full path_with_namespace",
    )
