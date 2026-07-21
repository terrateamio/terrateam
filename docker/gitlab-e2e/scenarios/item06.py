"""Audit item 06 / TEST-PLAN 3.7 -- commit statuses on GitLab.

Two halves, and only one of them inverts.

`details_url` was hardcoded to the empty string and the API sent
`target_url = None`, so the status on a merge request had no link back to the
run.  That is fixed and is asserted here.

Per-dirspace statuses are **not** expected, and the scenario asserts their
absence rather than their presence.  A GitLab commit status is attached to a
pipeline and the pipeline's status is the aggregate of its statuses, so a check
per dirspace would fold into the merge request's pipeline: one queued or failed
dirspace would drive the whole pipeline pending or failed, which feeds
detailed_merge_status as ci_must_pass and would block merges on Terrateam's own
bookkeeping.  So TEST-PLAN 3.7 does not invert as written, and this scenario
pins the current behaviour plus the check that mergeability still evaluates.
"""

from harness.scenario import scenario

from . import markers

APPLY_STATUS = "terrateam apply"


@scenario("3.7", "Commit status links to the run page and does not break mergeability", phase=3)
def commit_status_details_url(ctx):
    mr = None
    ctx.fixture.create()
    ctx.fixture.register_webhook()
    branch = ctx.fixture.branch_with_change("e2e/status", dirs=("dev", "prod"))
    mr = ctx.fixture.open_mr(branch)

    ctx.wait_for_note_containing(mr["iid"], markers.PLAN_COMPLETE)
    status = ctx.wait_for_status(
        mr["sha"], APPLY_STATUS, states=("success", "pending", "running", "failed")
    )

    # --- the link ------------------------------------------------------
    target = status.get("target_url")
    ctx.assert_true(bool(target), "the commit status carries a target_url (got %r)" % target)
    ctx.assert_true(
        target.startswith(ctx.cfg.terrateam_url + "/i/" + str(ctx.cfg.installation_id)),
        "the target_url points at this installation: %s" % target,
    )

    # --- the deliberate absence of per-dirspace statuses ---------------
    names = ctx.status_names(mr["sha"])
    ctx.log("commit statuses present: %s" % names)
    per_dirspace = [n for n in names if n.startswith("terrateam ") and (" dev " in n or " prod " in n)]
    ctx.assert_true(
        not per_dirspace,
        "no per-dirspace statuses are published, which is deliberate (found %s)" % per_dirspace,
    )

    # --- mergeability still evaluates ----------------------------------
    def mergeable():
        current = ctx.gl.merge_request(ctx.fixture.id, mr["iid"])
        dms = current.get("detailed_merge_status")
        ctx.log("detailed_merge_status=%s" % dms)
        # Anything other than a CI-blocked state means the statuses Terrateam
        # posted have not wedged the pipeline.
        return dms not in (None, "checking", "ci_still_running", "ci_must_pass") or None

    dms = ctx.wait_for("detailed_merge_status to settle", mergeable, timeout=180)
    ctx.log("settled on detailed_merge_status=%s" % dms)
