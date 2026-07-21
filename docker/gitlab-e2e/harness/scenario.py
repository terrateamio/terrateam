"""Scenario registry, execution context and assertions.

A scenario is a function registered with ``@scenario(id, description)`` that
takes a :class:`Ctx` and raises :class:`AssertionFailed` (or any exception) to
fail.  Everything a scenario needs to drive a real merge request and wait on
the live webhook -> pipeline -> comment/commit-status loop hangs off ``Ctx``.

Assertions prefer real API state -- GitLab notes, commit statuses, merge status
-- over log grepping.  Log grepping is available for the cases where the
observable outcome really is "nothing happened and nothing crashed".
"""

import subprocess
import time

REGISTRY = {}


class AssertionFailed(Exception):
    pass


class Timeout(AssertionFailed):
    pass


class Skipped(Exception):
    """Raised by a scenario that cannot run in the current environment."""


def scenario(id_, description, phase=None):
    def register(fn):
        if id_ in REGISTRY:
            raise RuntimeError("duplicate scenario id %s" % id_)
        fn.id = id_
        fn.description = description
        fn.phase = phase
        REGISTRY[id_] = fn
        return fn

    return register


class Ctx:
    def __init__(self, gl, cfg, fixture, log):
        self.gl = gl
        self.cfg = cfg
        self.fixture = fixture
        self.log = log
        self._started = time.time()

    # -- waiting -----------------------------------------------------------

    def wait_for(self, what, fn, timeout=None):
        """Poll ``fn`` until it returns something truthy, or time out.

        ``fn`` returning None/False means "not yet"; anything else is the
        result and is returned.
        """
        timeout = timeout or self.cfg.timeout
        deadline = time.time() + timeout
        last_report = 0.0
        while time.time() < deadline:
            result = fn()
            if result:
                self.log("ok: %s" % what)
                return result
            now = time.time()
            if now - last_report > 30:
                self.log("waiting for %s (%ds left)" % (what, int(deadline - now)))
                last_report = now
            time.sleep(self.cfg.poll_interval)
        raise Timeout("timed out after %ds waiting for %s" % (timeout, what))

    # -- merge request notes -----------------------------------------------

    def notes(self, iid):
        return self.gl.notes(self.fixture.id, iid)

    def wait_for_note(self, iid, predicate, what, timeout=None):
        def check():
            for note in self.notes(iid):
                if predicate(note["body"]):
                    return note
            return None

        return self.wait_for("note matching %s" % what, check, timeout=timeout)

    def wait_for_note_containing(self, iid, needle, timeout=None):
        return self.wait_for_note(
            iid, lambda body: needle in body, "%r" % needle, timeout=timeout
        )

    def assert_no_note_containing(self, iid, needle):
        for note in self.notes(iid):
            if needle in note["body"]:
                raise AssertionFailed(
                    "did not expect a note containing %r, found note %s" % (needle, note["id"])
                )

    def comment(self, iid, body):
        self.log("commenting %r on !%d" % (body, iid))
        return self.gl.create_note(self.fixture.id, iid, body)

    def comment_as_approver(self, iid, body):
        """Comment as the second account.

        Needed wherever the acting user must not be the merge request author --
        gate approvals in particular, which the server excludes when the
        approver opened the merge request.
        """
        if not self.cfg.approver_token:
            raise Skipped(
                "GITLAB_APPROVER_TOKEN is not set, and this needs a user who is not the "
                "merge request author"
            )
        from . import gitlab as gitlab_mod

        other = gitlab_mod.Gitlab(self.cfg.gitlab_api_url, self.cfg.approver_token)
        # Group membership does not reach a project created moments ago, so
        # invite the account explicitly.  Harmless if it is already a member.
        who = other.current_user()
        try:
            self.gl.add_project_member(self.fixture.id, who["id"])
            self.log("invited %s to the fixture project" % who["username"])
        except gitlab_mod.GitlabError as exc:
            if exc.status not in (409, 400):
                raise
        self.log("commenting %r on !%d as %s" % (body, iid, who["username"]))
        return gitlab_mod.retry(lambda: other.create_note(self.fixture.id, iid, body))

    # -- commit statuses ---------------------------------------------------

    def statuses(self, sha):
        return self.gl.commit_statuses(self.fixture.id, sha)

    def wait_for_status(self, sha, name, states=("success",), timeout=None):
        def check():
            for status in self.statuses(sha):
                if status["name"] == name and status["status"] in states:
                    return status
            return None

        return self.wait_for(
            "commit status %r in %s" % (name, "/".join(states)), check, timeout=timeout
        )

    def status_names(self, sha):
        return sorted({s["name"] for s in self.statuses(sha)})

    # -- pipelines ---------------------------------------------------------

    def wait_for_pipeline(self, ref, timeout=None):
        def check():
            pipelines = self.gl.pipelines(self.fixture.id, ref=ref, per_page=1)
            return pipelines[0] if pipelines else None

        return self.wait_for("a pipeline on %s" % ref, check, timeout=timeout)

    # -- server side -------------------------------------------------------

    def server_logs(self):
        """Terrateam server logs produced since this scenario started.

        The window matters.  Scenarios run in sequence against one long-lived
        server, so a fixed window such as ``--since 15m`` makes one scenario
        assert on lines an earlier scenario produced -- which reads as a
        failure in the wrong scenario.  ``{since}`` in TERRATEAM_LOGS_CMD is
        substituted with this scenario's own age.
        """
        if not self.cfg.logs_cmd:
            raise Skipped("TERRATEAM_LOGS_CMD is not set, cannot inspect server logs")
        cmd = self.cfg.logs_cmd
        if "{since}" in cmd:
            # A few seconds of slack for clock skew between here and the server.
            cmd = cmd.replace("{since}", "%ds" % (int(time.time() - self._started) + 5))
        else:
            self.log(
                "warning: TERRATEAM_LOGS_CMD has no {since} placeholder, so log "
                "assertions can pick up lines from earlier scenarios"
            )
        proc = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=120)
        return proc.stdout + proc.stderr

    def assert_not_in_logs(self, needle):
        logs = self.server_logs()
        hits = [line for line in logs.splitlines() if needle in line]
        if hits:
            raise AssertionFailed(
                "found %d log line(s) containing %r, first: %s" % (len(hits), needle, hits[0])
            )
        self.log("ok: no %r in server logs" % needle)

    def psql(self, sql):
        """Run a read-only query against the Terrateam database."""
        if not self.cfg.psql:
            raise Skipped("TERRATEAM_PSQL is not set, cannot query the Terrateam database")
        proc = subprocess.run(
            self.cfg.psql + " -tAc " + _shell_quote(sql),
            shell=True,
            capture_output=True,
            text=True,
            timeout=120,
        )
        if proc.returncode != 0:
            raise AssertionFailed("psql failed: %s" % (proc.stderr.strip(),))
        # A multi-statement query prints a command tag per statement (BEGIN,
        # ROLLBACK, INSERT 0 1, ...) interleaved with the rows.  Drop the tags
        # so callers only see result rows.
        tags = ("BEGIN", "COMMIT", "ROLLBACK", "SET")
        prefixes = ("INSERT ", "UPDATE ", "DELETE ", "SELECT ", "CREATE ", "DROP ")
        return [
            line
            for line in (l.strip() for l in proc.stdout.strip().splitlines())
            if line and line not in tags and not line.startswith(prefixes)
        ]

    # -- generic -----------------------------------------------------------

    def assert_names_dirspace(self, body, dir_, present=True):
        """Assert a comment does (or does not) report a run for ``dir_``.

        The plan and apply templates render a dirspace two different ways: as a
        row in the summary table (`` `dev` ``) when notifications.summary is
        enabled, and as a per-dirspace section otherwise.  Accept either, so the
        assertion is about the dirspace having run rather than about which
        template branch produced the comment.
        """
        forms = ["`%s`" % dir_, "**Dir**: %s" % dir_, "## %s |" % dir_]
        found = [f for f in forms if f in body]
        if present and not found:
            raise AssertionFailed(
                "comment does not report a run for %r (looked for %s)" % (dir_, forms)
            )
        if not present and found:
            raise AssertionFailed("comment unexpectedly reports a run for %r via %s" % (dir_, found))
        self.log(
            "ok: comment %s a run for %r" % ("reports" if present else "does not report", dir_)
        )

    def assert_true(self, cond, message):
        if not cond:
            raise AssertionFailed(message)
        self.log("ok: %s" % message)

    def assert_eq(self, actual, expected, message):
        if actual != expected:
            raise AssertionFailed("%s: expected %r, got %r" % (message, expected, actual))
        self.log("ok: %s" % message)


def _shell_quote(s):
    return "'" + s.replace("'", "'\\''") + "'"
