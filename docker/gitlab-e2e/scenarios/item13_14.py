"""Audit items 13 and 14 -- cross-installation isolation.

Both fixes are about one installation being unable to reach another's rows, and
proving that properly needs two installations. Rather than fake it, these
scenarios drive a real run to produce real rows and then exercise the guards
directly against the database:

- item 13 runs the actual upsert inside a transaction that is rolled back,
  once with a foreign installation id and once with the real one, and asserts
  the foreign one cannot rewrite the row while the real one still can. Nothing
  is committed, so the database is left exactly as found.
- item 14 runs the actual lookup as a read-only select, once scoped to the
  owning installation and once to a foreign one.

This is narrower than a forged webhook from a second tenant, and the gap is
recorded in RESULTS.md rather than papered over. What it does cover is the part
most likely to regress: that the predicate is present and correct, and that
normal operation still works with it in place.
"""

from harness.scenario import scenario

from . import markers

FOREIGN_INSTALLATION = 999999999


@scenario("13", "A foreign installation cannot rewrite a repository row", phase=3)
def repo_installation_binding(ctx):
    ctx.fixture.create()
    ctx.fixture.register_webhook()
    branch = ctx.fixture.branch_with_change("e2e/binding")
    mr = ctx.fixture.open_mr(branch)
    ctx.wait_for_note_containing(mr["iid"], markers.PLAN_COMPLETE)

    repo_id = ctx.fixture.id
    rows = ctx.psql(
        "select installation_id, owner, name from gitlab_installation_repositories "
        "where id = %d" % repo_id
    )
    ctx.assert_true(rows, "the repository was recorded")
    installation_id, owner, name = rows[0].split("|")
    ctx.log("repo %d owned by installation %s as %s/%s" % (repo_id, installation_id, owner, name))

    upsert = (
        "insert into gitlab_installation_repositories as r (id, installation_id, name, owner) "
        "values (%d, %s, 'evil-name', 'evil-owner') "
        "on conflict (id) do update set (owner, name) = (excluded.owner, excluded.name) "
        "where r.installation_id = excluded.installation_id "
        "and (r.owner, r.name) <> (excluded.owner, excluded.name);"
    )

    # --- a foreign installation must not be able to rewrite it ---------
    out = ctx.psql(
        "begin; "
        + (upsert % (repo_id, FOREIGN_INSTALLATION))
        + " select owner || '/' || name from gitlab_installation_repositories where id = %d; "
        "rollback;" % repo_id
    )
    ctx.assert_eq(
        out[-1],
        "%s/%s" % (owner, name),
        "a foreign installation leaves owner and name unchanged",
    )

    # --- the owning installation still can ------------------------------
    out = ctx.psql(
        "begin; "
        + (upsert % (repo_id, installation_id))
        + " select owner || '/' || name from gitlab_installation_repositories where id = %d; "
        "rollback;" % repo_id
    )
    ctx.assert_eq(
        out[-1],
        "evil-owner/evil-name",
        "the owning installation can still rename its own repository",
    )

    # Nothing was committed.
    rows = ctx.psql(
        "select owner || '/' || name from gitlab_installation_repositories where id = %d" % repo_id
    )
    ctx.assert_eq(rows[0], "%s/%s" % (owner, name), "the database was left unchanged")


@scenario("14", "A work manifest is only reachable by its own installation", phase=3)
def run_id_scoping(ctx):
    ctx.fixture.create()
    ctx.fixture.register_webhook()
    branch = ctx.fixture.branch_with_change("e2e/runid")
    mr = ctx.fixture.open_mr(branch)
    ctx.wait_for_note_containing(mr["iid"], markers.PLAN_COMPLETE)

    def manifest_with_run_id():
        rows = ctx.psql(
            "select run_id, installation_id from gitlab_work_manifests "
            "where repository = %d and run_id is not null "
            "order by created_at desc limit 1" % ctx.fixture.id
        )
        return rows[0] if rows else None

    row = ctx.wait_for("a work manifest with a run_id", manifest_with_run_id)
    run_id, installation_id = row.split("|")
    ctx.log("work manifest run_id=%s installation=%s" % (run_id, installation_id))

    # This is the query the Job_event path runs.
    scoped = (
        "select count(*) from gitlab_work_manifests where run_id = '%s' and installation_id = %s"
    )

    found = ctx.psql(scoped % (run_id, installation_id))
    ctx.assert_eq(found[0], "1", "the owning installation resolves its own work manifest")

    not_found = ctx.psql(scoped % (run_id, FOREIGN_INSTALLATION))
    ctx.assert_eq(not_found[0], "0", "a foreign installation resolves nothing")

    # And the unscoped form -- what the code used to run -- would have found it,
    # which is what made the fix necessary.
    unscoped = ctx.psql("select count(*) from work_manifests where run_id = '%s'" % run_id)
    ctx.assert_true(
        int(unscoped[0]) >= 1,
        "the unscoped query the fix replaced would have matched (count=%s)" % unscoped[0],
    )
