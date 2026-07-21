"""Strings the scenarios assert on.

These come from the comment templates in
``code/src/terrat_vcs_gitlab_comment_templates/tmpl``.  Keeping them in one
place means a template rename breaks in an obvious spot rather than in eight
scenarios at once.
"""

# tmpl/plan_complete2.tmpl
PLAN_COMPLETE = "## Plans"
# tmpl/apply_complete2.tmpl
APPLY_COMPLETE = "## Applies"
# tmpl/unlock_success.tmpl
UNLOCK_SUCCESS = "All directories and workspaces have been unlocked."
# tmpl/plan_complete2.tmpl, only rendered once work_manifest_url is defined
WORK_MANIFEST_URL = "Outputs can be viewed in the Terrateam Console"
# tmpl/gate_check_failure.tmpl
GATE_BLOCKED = "Gatekeeper Requirements Not Satisfied"
# tmpl/premium_feature_err_gatekeeping.tmpl
GATE_PREMIUM = "Gatekeeping is a Commercial Feature"
# tmpl/plan_complete2.tmpl, the two overall_success branches
PLAN_SUCCESS = "## Plans :thumbsup:"
PLAN_FAILURE = "## Plans :heavy_multiplication_x:"
# tmpl/comment_too_large.tmpl
COMMENT_TOO_LARGE = "exceeds the GitLab comment size and cannot be displayed"

# The exception text the GitLab service used to raise on unhandled webhook
# input.  Its absence from the logs is the assertion for item 03.
NYI = 'Failure("nyi")'
