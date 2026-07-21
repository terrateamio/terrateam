"""Audit item 04 / TEST-PLAN 3.8 -- work-manifest API access tokens.

Before the fix the four post-initiate endpoints called
``enforce_work_manifest_access (Some work_manifest_id) work_manifest_id``,
comparing the URL path parameter to itself, so the check always passed and
knowing the work manifest id was the entire credential.  After the fix they
take the caller's access token from the session and require it to be the work
manifest's token.

**This scenario is expected to fail against main today, and that is the point.**

Running it against a build with the server-side checks enabled proved the
enforcement cannot ship yet: the GitLab runner authenticates by putting the raw
work manifest id in the URL path and never sends an Authorization header at
all, so turning the checks on returns 403 to the runner and no plan ever
completes.  See items/04 for the evidence.

It therefore stands as the acceptance test for the coordinated change that
closes item 04: teach terrat-runner to send the token the initiate response
already returns, roll that out, and only then enable the server checks.  When
both halves below pass, the item is done.

Both halves matter: the failure path first, then the happy path, because a
scenario that only proves calls get rejected would also pass if the whole
service were down.
"""

import json
import urllib.error
import urllib.request

from harness.scenario import Skipped, scenario

from . import markers


def _call(url, method="GET", token=None, body=None):
    """Call the work-manifest API directly and return the status code."""
    data = json.dumps(body).encode() if body is not None else None
    headers = {}
    if data:
        headers["Content-Type"] = "application/json"
    if token:
        headers["Authorization"] = "Bearer " + token
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return resp.status
    except urllib.error.HTTPError as exc:
        return exc.code
    except urllib.error.URLError as exc:
        raise Skipped("cannot reach the Terrateam work-manifest API: %s" % exc) from None


@scenario("3.8", "Work-manifest API rejects calls without the access token", phase=3)
def work_manifest_requires_token(ctx):
    api = ctx.cfg.terrateam_url + "/api/gitlab/v1/work-manifests"

    # Drive a real run so there is a work manifest in a queued/running state to
    # aim at.  Without one the endpoints would reject on the state check rather
    # than the token check, and the test would pass for the wrong reason.
    ctx.fixture.create()
    ctx.fixture.register_webhook()
    branch = ctx.fixture.branch_with_change("e2e/wm-token")
    mr = ctx.fixture.open_mr(branch)

    def running_manifest():
        rows = ctx.psql(
            "select wm.id from work_manifests wm "
            "join gitlab_work_manifests gwm on gwm.id = wm.id "
            "where gwm.repository = %d and wm.state in ('queued','running') "
            "order by wm.created_at desc limit 1" % ctx.fixture.id
        )
        return rows[0] if rows else None

    work_manifest_id = ctx.wait_for("a queued or running work manifest", running_manifest)
    ctx.log("aiming at work manifest %s" % work_manifest_id)

    # --- failure path -----------------------------------------------------
    # No Authorization header at all.  Before the fix these returned 200/404
    # depending on the endpoint; after it they must be refused.
    for method, path, body in (
        ("GET", "/%s/workspaces" % work_manifest_id, None),
        # The GET route's query parameters are path and workspace, not dir --
        # getting them wrong routes to nothing and returns 404, which would
        # look like a pass if the assertion accepted it.
        ("GET", "/%s/plans?path=dev&workspace=default" % work_manifest_id, None),
        (
            "POST",
            "/%s/plans" % work_manifest_id,
            {"path": "dev", "workspace": "default", "plan_data": "", "has_changes": False},
        ),
    ):
        status = _call(api + path, method=method, token=None)
        # 404 is explicitly not accepted: it means the route did not match, so
        # the call never reached the check being tested.
        ctx.assert_true(
            status in (401, 403),
            "%s %s without a token is refused (got %s)" % (method, path.split("?")[0], status),
        )

    # A well-formed but wrong bearer token must also be refused, so the check is
    # really on the token and not merely on the header being present.
    status = _call(api + "/%s/workspaces" % work_manifest_id, token="not-a-real-token")
    ctx.assert_true(
        status in (401, 403),
        "a bogus bearer token is refused (got %s)" % status,
    )

    # --- happy path -------------------------------------------------------
    # The runner authenticates with the token it got from initiate, so if
    # enforcement were wrong this run would never produce a plan comment.
    ctx.wait_for_note_containing(mr["iid"], markers.PLAN_COMPLETE)
    ctx.assert_not_in_logs(markers.NYI)
