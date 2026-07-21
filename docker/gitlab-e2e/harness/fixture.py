"""The fixture Terraform project a scenario runs against.

Each run creates its own project so scenarios never contaminate each other and
can run unattended in sequence.  The project is deleted on teardown unless
E2E_KEEP is set.

The layout matches the audit's TEST-PLAN: three directories so dirspace
targeting is exercisable, and null_resource-only Terraform so no cloud
credentials are ever needed.
"""

import time

from . import gitlab

# The pipeline spec Terrateam triggers.  The four inputs are exactly what
# Terrat_vcs_service_gitlab_provider.build_pipeline_inputs sends
# (TERRATEAM_TRIGGER, WORK_TOKEN, API_BASE_URL and optionally RUNS_ON).  Every
# one needs a default, or GitLab rejects the trigger and the server reports
# GITLAB_INPUTS_MISSING_DEFAULTS.
GITLAB_CI_YML = """\
spec:
  inputs:
    TERRATEAM_TRIGGER:
      description: "Is this being triggered by terrateam?"
      type: string
      default: "$TERRATEAM_TRIGGER"
    WORK_TOKEN:
      description: "The work token from terrateam"
      type: string
      default: "$WORK_TOKEN"
    API_BASE_URL:
      description: "The base url for the terrateam api"
      type: string
      default: "$API_BASE_URL"
    RUNS_ON:
      description: "The tags to use for the runner"
      type: array
      default: []
---
include:
  - project: 'terrateam-io/terrateam-template'
    file: 'terrateam-template.yml'
    inputs:
      TERRATEAM_TRIGGER: $[[ inputs.TERRATEAM_TRIGGER ]]
      WORK_TOKEN: $[[ inputs.WORK_TOKEN ]]
      API_BASE_URL: $[[ inputs.API_BASE_URL ]]
      RUNS_ON: $[[ inputs.RUNS_ON ]]

stages:
  - terrateam

terrateam_job:
  extends: .terrateam_template
"""

# notifications.summary.enabled defaults to false, and the per-dirspace table in
# the plan and apply comments is only rendered when it is on.  Scenarios that
# assert on which dirspaces ran need that table, so the fixture turns it on.
DEFAULT_CONFIG_YML = """\
notifications:
  summary:
    enabled: true
when_modified:
  file_patterns:
    - '${DIR}/*.tf'
"""

MODULE_TF = """\
variable "name" {
  type = string
}

resource "null_resource" "shared" {
  triggers = {
    name = var.name
  }
}
"""


def _root_tf(name):
    return """\
terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

module "shared" {
  source = "../modules/shared"
  name   = "%s"
}

resource "null_resource" "%s" {
  triggers = {
    # Bumping this value is how a scenario creates a plan diff.
    revision = "1"
  }
}
""" % (name, name)


def base_files(config_yml=DEFAULT_CONFIG_YML):
    return {
        ".gitlab-ci.yml": GITLAB_CI_YML,
        ".terrateam/config.yml": config_yml,
        "modules/shared/main.tf": MODULE_TF,
        "dev/main.tf": _root_tf("dev"),
        "prod/main.tf": _root_tf("prod"),
        "README.md": "Terrateam GitLab e2e fixture. Created by docker/gitlab-e2e.\n",
    }


class Fixture:
    """A throwaway GitLab project seeded with the Terraform fixture."""

    def __init__(self, gl, cfg, log, name):
        self._gl = gl
        self._cfg = cfg
        self._log = log
        self.name = name
        self.project = None
        self.hook = None
        self._created_groups = []
        self._branches = set()

    @property
    def id(self):
        return self.project["id"]

    @property
    def path(self):
        return self.project["path_with_namespace"]

    @property
    def default_branch(self):
        return self.project.get("default_branch") or "main"

    def create(self, config_yml=DEFAULT_CONFIG_YML, files=None, subgroups=()):
        """Seed the fixture project.

        ``subgroups`` nests the project that many levels below the configured
        group, which is how the deep ``path_with_namespace`` shapes in audit
        item 03 get exercised.  The subgroups are deleted with the project.
        """
        parent = self._gl.group(self._cfg.group)
        parent_path = self._cfg.group
        for name in subgroups:
            parent = self._gl.post(
                "/groups",
                body={
                    "name": name,
                    "path": name,
                    "parent_id": parent["id"],
                    "visibility": "private",
                },
            )
            parent_path = parent["full_path"]
            self._created_groups.append(parent["id"])
        self._log("creating project %s/%s" % (parent_path, self.name))
        self.project = self._gl.create_project(
            self.name,
            parent["id"],
            default_branch="main",
            description="Terrateam GitLab e2e fixture (throwaway)",
        )

        content = base_files(config_yml)
        if files:
            content.update(files)
        actions = [
            {"action": "create", "file_path": path, "content": body}
            for path, body in sorted(content.items())
        ]
        # A freshly created project is not immediately consistent on
        # gitlab.com: the project exists but its repository can still 404 for a
        # second or two, so the seeding commit has to be retried.
        gitlab.retry(
            lambda: self._gl.commit(self.id, "main", "ADD Terrateam e2e fixture", actions),
            attempts=6,
            delay=2,
        )
        # A freshly created project reports no default_branch until the first
        # commit lands.
        self.project = self._gl.project(self.id)
        self._log("seeded %s (id %d)" % (self.path, self.id))
        return self

    def register_webhook(self):
        """Point the project at the Terrateam server under test.

        The token is the per-installation webhook secret; the server resolves
        the installation from it, which is the only thing authenticating the
        event.
        """
        self._log("registering webhook -> %s" % self._cfg.webhook_url)
        self.hook = self._gl.create_project_hook(
            self.id, self._cfg.webhook_url, self._cfg.webhook_secret
        )
        return self.hook

    # -- convenience used by scenarios -------------------------------------

    def branch_with_change(self, branch, dirs=("dev",), revision="2", message=None):
        """Commit a change to the given dirs, producing a plan diff.

        Creates ``branch`` off the default branch the first time and commits
        onto it thereafter, which is what a scenario pushing a second commit to
        an open merge request needs.  GitLab rejects ``start_branch`` for a
        branch that already exists.
        """
        actions = []
        for d in dirs:
            body = _root_tf(d).replace('revision = "1"', 'revision = "%s"' % revision)
            actions.append({"action": "update", "file_path": "%s/main.tf" % d, "content": body})
        start_branch = None if branch in self._branches else self.default_branch
        gitlab.retry(
            lambda: self._gl.commit(
                self.id,
                branch,
                message or ("CHG Touch %s" % ", ".join(dirs)),
                actions,
                start_branch=start_branch,
            ),
            attempts=6,
            delay=2,
        )
        self._branches.add(branch)
        return branch

    def open_mr(self, branch, title=None):
        mr = self._gl.create_merge_request(
            self.id, branch, self.default_branch, title or ("e2e: %s" % branch)
        )
        self._log("opened MR !%d %s" % (mr["iid"], mr["web_url"]))
        return mr

    def destroy(self):
        if self.project is None:
            return
        if self._cfg.keep:
            self._log("E2E_KEEP set, leaving %s behind" % self.path)
            return
        self._log("deleting %s" % self.path)
        try:
            self._gl.delete_project(self.id)
        except Exception as exc:  # teardown must never mask a test failure
            self._log("teardown warning: %s" % exc)
        # Innermost first, so a parent is never deleted while it still has
        # children.
        for group_id in reversed(self._created_groups):
            try:
                self._gl.delete("/groups/%d" % group_id)
            except Exception as exc:  # noqa: BLE001
                self._log("teardown warning (group %d): %s" % (group_id, exc))


def unique_name(prefix):
    return "tt-e2e-%s-%d" % (prefix, int(time.time()))
