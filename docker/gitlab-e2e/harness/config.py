"""Configuration for the GitLab e2e harness.

Every value comes from the environment so the harness can be pointed at any
GitLab (gitlab.com or self-hosted) and any Terrateam server without edits.  See
``env.example`` for the contract and ``README.md`` for how the pieces fit
together.
"""

import os
import sys


class ConfigError(Exception):
    pass


def _require(name):
    value = os.environ.get(name)
    if not value:
        raise ConfigError(
            "%s is not set.  Copy env.example to .env, fill it in, and source it." % name
        )
    return value


class Config:
    def __init__(self):
        # GitLab
        self.gitlab_url = os.environ.get("GITLAB_WEB_BASE_URL", "https://gitlab.com").rstrip("/")
        self.gitlab_api_url = os.environ.get(
            "GITLAB_API_BASE_URL", self.gitlab_url + "/api/v4"
        ).rstrip("/")
        self.gitlab_token = _require("GITLAB_ACCESS_TOKEN")

        # Where fixture projects are created.  This group MUST be the one the
        # Terrateam installation was installed against, because the server acts
        # on the repo with that installation's access token.
        self.group = _require("GITLAB_TEST_GROUP")

        # A second GitLab account, used where one user acting alone cannot
        # produce the situation under test.  Gate approvals are the case that
        # needs it: select_gate_approvals excludes approvals whose approver is
        # the merge request author, so a gate can never be satisfied by the
        # person who opened the merge request.  Scenarios that need this skip
        # when it is unset rather than failing.
        self.approver_token = os.environ.get("GITLAB_APPROVER_TOKEN")

        # Terrateam
        self.terrateam_url = _require("TERRATEAM_WEB_BASE_URL").rstrip("/")
        self.webhook_url = os.environ.get(
            "TERRATEAM_WEBHOOK_URL", self.terrateam_url + "/api/v1/gitlab/events"
        )
        # The per-installation webhook secret, sent as X-Gitlab-Token.  Read it
        # from gitlab_installations.webhook_secret for the installation under
        # test.
        self.webhook_secret = _require("TERRATEAM_WEBHOOK_SECRET")
        self.installation_id = _require("TERRATEAM_INSTALLATION_ID")

        # Optional: a psql command that reaches the Terrateam database, used by
        # scenarios that assert on server-side state rather than GitLab state.
        # Example: "docker compose -f /root/demo/docker-compose.yml exec -T db
        #           psql -U stategraph -d terrateam"
        self.psql = os.environ.get("TERRATEAM_PSQL")

        # Optional: a shell command that prints recent Terrateam server logs,
        # used by the scenarios whose expected outcome is "nothing happened and
        # nothing crashed".  Example: "docker compose -f
        # /root/demo/docker-compose.yml logs --since 10m terrateam-server"
        self.logs_cmd = os.environ.get("TERRATEAM_LOGS_CMD")

        # Timeouts, in seconds.  GitLab pipelines on shared runners are slow;
        # these are deliberately generous.
        self.timeout = int(os.environ.get("E2E_TIMEOUT", "600"))
        self.poll_interval = int(os.environ.get("E2E_POLL_INTERVAL", "5"))

        # Leave the fixture project behind for debugging.
        self.keep = os.environ.get("E2E_KEEP", "") not in ("", "0", "false")

        # Terraform runner tags, if the group uses a specific runner.
        runs_on = os.environ.get("E2E_RUNS_ON", "")
        self.runs_on = [t for t in runs_on.split(",") if t]


def load():
    try:
        return Config()
    except ConfigError as exc:
        print("config error: %s" % exc, file=sys.stderr)
        raise SystemExit(2)
