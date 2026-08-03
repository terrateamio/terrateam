"""A small GitLab API client.

Deliberately stdlib-only: the harness has to run from a clean checkout and in
CI without a pip install step, and it needs a small enough surface that the
whole thing can be read in one sitting.  Only the calls the scenarios actually
make are implemented.
"""

import json
import time
import urllib.error
import urllib.parse
import urllib.request


class GitlabError(Exception):
    def __init__(self, status, method, path, body):
        self.status = status
        self.body = body
        super().__init__("%s %s -> %s: %s" % (method, path, status, body))


class Gitlab:
    def __init__(self, api_url, token):
        self._api_url = api_url.rstrip("/")
        self._token = token

    # -- plumbing ----------------------------------------------------------

    def request(self, method, path, body=None, params=None, raw=False):
        url = self._api_url + path
        if params:
            url += "?" + urllib.parse.urlencode(params)
        data = None
        headers = {"PRIVATE-TOKEN": self._token}
        if body is not None:
            data = json.dumps(body).encode()
            headers["Content-Type"] = "application/json"
        req = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                payload = resp.read()
        except urllib.error.HTTPError as exc:
            raise GitlabError(exc.code, method, path, exc.read().decode(errors="replace")) from None
        if raw:
            return payload.decode(errors="replace")
        if not payload:
            return None
        return json.loads(payload)

    def get(self, path, params=None, raw=False):
        return self.request("GET", path, params=params, raw=raw)

    def post(self, path, body=None, params=None):
        return self.request("POST", path, body=body, params=params)

    def put(self, path, body=None, params=None):
        return self.request("PUT", path, body=body, params=params)

    def delete(self, path):
        return self.request("DELETE", path)

    # -- identity ----------------------------------------------------------

    def version(self):
        return self.get("/version")

    def current_user(self):
        return self.get("/user")

    def group(self, path):
        return self.get("/groups/" + urllib.parse.quote(path, safe=""))

    # -- projects ----------------------------------------------------------

    def create_project(self, name, namespace_id, **kwargs):
        body = {
            "name": name,
            "path": name,
            "namespace_id": namespace_id,
            "visibility": "private",
            "initialize_with_readme": False,
        }
        body.update(kwargs)
        return self.post("/projects", body=body)

    def delete_project(self, project_id):
        return self.delete("/projects/%d" % project_id)

    def project(self, project_id):
        return self.get("/projects/%d" % project_id)

    # -- files and commits -------------------------------------------------

    def commit(self, project_id, branch, message, actions, start_branch=None):
        """Create a commit from a list of {action, file_path, content} dicts."""
        body = {"branch": branch, "commit_message": message, "actions": actions}
        if start_branch:
            body["start_branch"] = start_branch
        return self.post("/projects/%d/repository/commits" % project_id, body=body)

    def file_raw(self, project_id, path, ref):
        return self.get(
            "/projects/%d/repository/files/%s/raw" % (project_id, urllib.parse.quote(path, safe="")),
            params={"ref": ref},
            raw=True,
        )

    # -- merge requests ----------------------------------------------------

    def create_merge_request(self, project_id, source_branch, target_branch, title):
        return self.post(
            "/projects/%d/merge_requests" % project_id,
            body={
                "source_branch": source_branch,
                "target_branch": target_branch,
                "title": title,
            },
        )

    def merge_request(self, project_id, iid):
        return self.get("/projects/%d/merge_requests/%d" % (project_id, iid))

    def update_merge_request(self, project_id, iid, **kwargs):
        return self.put("/projects/%d/merge_requests/%d" % (project_id, iid), body=kwargs)

    def merge_merge_request(self, project_id, iid, sha=None):
        """Merge an MR.

        GitLab requires ``sha`` when the project has "merge only if pipeline
        succeeds" or an equivalent guard, and returns 400 "SHA must be provided
        when merging" otherwise, so pass the head sha.
        """
        body = {}
        if sha:
            body["sha"] = sha
        return self.put("/projects/%d/merge_requests/%d/merge" % (project_id, iid), body=body)

    def approve_merge_request(self, project_id, iid):
        return self.post("/projects/%d/merge_requests/%d/approve" % (project_id, iid))

    def unapprove_merge_request(self, project_id, iid):
        return self.post("/projects/%d/merge_requests/%d/unapprove" % (project_id, iid))

    def notes(self, project_id, iid):
        return self.get(
            "/projects/%d/merge_requests/%d/notes" % (project_id, iid),
            params={"per_page": 100, "sort": "asc", "order_by": "created_at"},
        )

    def create_note(self, project_id, iid, body):
        return self.post(
            "/projects/%d/merge_requests/%d/notes" % (project_id, iid), body={"body": body}
        )

    # -- statuses and pipelines --------------------------------------------

    def commit_statuses(self, project_id, sha):
        return self.get(
            "/projects/%d/repository/commits/%s/statuses" % (project_id, sha),
            params={"per_page": 100},
        )

    def pipelines(self, project_id, **params):
        return self.get("/projects/%d/pipelines" % project_id, params=params or None)

    def pipeline_jobs(self, project_id, pipeline_id):
        return self.get("/projects/%d/pipelines/%d/jobs" % (project_id, pipeline_id))

    def job_trace(self, project_id, job_id):
        return self.get("/projects/%d/jobs/%d/trace" % (project_id, job_id), raw=True)

    def add_project_member(self, project_id, user_id, access_level=30):
        """Invite a user to a project.  30 is Developer."""
        return self.post(
            "/projects/%d/members" % project_id,
            body={"user_id": user_id, "access_level": access_level},
        )

    # -- webhooks ----------------------------------------------------------

    def create_project_hook(self, project_id, url, token):
        return self.post(
            "/projects/%d/hooks" % project_id,
            body={
                "url": url,
                "token": token,
                "push_events": True,
                "merge_requests_events": True,
                "note_events": True,
                "pipeline_events": True,
                "job_events": True,
                "enable_ssl_verification": True,
            },
        )

    def test_project_hook(self, project_id, hook_id, trigger="push_events"):
        return self.post("/projects/%d/hooks/%d/test/%s" % (project_id, hook_id, trigger))


def retry(fn, attempts=5, delay=2, on=(GitlabError,)):
    """GitLab occasionally 5xxs or returns a not-yet-consistent read."""
    last = None
    for attempt in range(attempts):
        try:
            return fn()
        except on as exc:  # noqa: PERF203 - retry loop
            last = exc
            if getattr(exc, "status", 500) < 500 and getattr(exc, "status", 500) != 404:
                raise
            time.sleep(delay * (attempt + 1))
    raise last
