"""Audit item 07 / TEST-PLAN 3.5 -- comments link to the Terrateam run page.

`Ui.work_manifest_url` returned None on GitLab, and the plan and apply templates
render the Console link only when `work_manifest_url` is defined, so no GitLab
comment ever linked back to the run.

Note the item's framing is slightly off: the `Ui` module that *raised*
`Failure "nyi"` lives in terrat_vcs_gitlab_comment_templates and is referenced
by nothing.  The one on the publishing path is in terrat_vcs_gitlab_comment and
returned None, so the symptom was a missing link rather than a crash.
"""

from harness.scenario import scenario

from . import markers


@scenario("3.5", "Plan comments link to the Terrateam run page", phase=3)
def comment_links_to_run_page(ctx):
    ctx.fixture.create()
    ctx.fixture.register_webhook()
    branch = ctx.fixture.branch_with_change("e2e/ui-link")
    mr = ctx.fixture.open_mr(branch)

    note = ctx.wait_for_note_containing(mr["iid"], markers.PLAN_COMPLETE)
    ctx.assert_true(
        markers.WORK_MANIFEST_URL in note["body"],
        "the plan comment renders the Terrateam Console link",
    )
    # The link must point at this installation's run page on the configured UI
    # base, not at some placeholder.
    expected = "%s/i/%s/runs/pr/%d" % (
        ctx.cfg.terrateam_url,
        ctx.cfg.installation_id,
        mr["iid"],
    )
    ctx.assert_true(
        expected in note["body"],
        "the link is %s" % expected,
    )
