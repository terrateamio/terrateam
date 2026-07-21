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
        """Recent Terrateam server logs, if the environment exposes them."""
        if not self.cfg.logs_cmd:
            raise Skipped("TERRATEAM_LOGS_CMD is not set, cannot inspect server logs")
        proc = subprocess.run(
            self.cfg.logs_cmd, shell=True, capture_output=True, text=True, timeout=120
        )
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
        return [line for line in proc.stdout.strip().splitlines() if line]

    # -- generic -----------------------------------------------------------

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
