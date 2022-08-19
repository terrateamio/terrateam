module App = Terrat_github_webhooks_app
module Author_association = Terrat_github_webhooks_author_association
module Auto_merge = Terrat_github_webhooks_auto_merge
module Commit = Terrat_github_webhooks_commit
module Commit_simple = Terrat_github_webhooks_commit_simple
module Committer = Terrat_github_webhooks_committer
module Installation = Terrat_github_webhooks_installation
module Installation_created = Terrat_github_webhooks_installation_created
module Installation_deleted = Terrat_github_webhooks_installation_deleted

module Installation_new_permissions_accepted =
  Terrat_github_webhooks_installation_new_permissions_accepted

module Installation_suspend = Terrat_github_webhooks_installation_suspend
module Installation_unsuspend = Terrat_github_webhooks_installation_unsuspend
module Installation_lite = Terrat_github_webhooks_installation_lite
module Installation_event = Terrat_github_webhooks_installation_event
module Installation_repositories_added = Terrat_github_webhooks_installation_repositories_added
module Installation_repositories_removed = Terrat_github_webhooks_installation_repositories_removed
module Installation_repositories_event = Terrat_github_webhooks_installation_repositories_event
module Issue = Terrat_github_webhooks_issue
module Issue_any = Terrat_github_webhooks_issue_any
module Issue_comment = Terrat_github_webhooks_issue_comment
module Issue_comment_created = Terrat_github_webhooks_issue_comment_created
module Issue_comment_deleted = Terrat_github_webhooks_issue_comment_deleted
module Issue_comment_edited = Terrat_github_webhooks_issue_comment_edited
module Issue_comment_event = Terrat_github_webhooks_issue_comment_event
module Label = Terrat_github_webhooks_label
module License = Terrat_github_webhooks_license
module Link = Terrat_github_webhooks_link
module Milestone = Terrat_github_webhooks_milestone
module Organization = Terrat_github_webhooks_organization
module Pull_request = Terrat_github_webhooks_pull_request
module Pull_request_review_comment = Terrat_github_webhooks_pull_request_review_comment
module Pull_request_assigned = Terrat_github_webhooks_pull_request_assigned
module Pull_request_auto_merge_disabled = Terrat_github_webhooks_pull_request_auto_merge_disabled
module Pull_request_auto_merge_enabled = Terrat_github_webhooks_pull_request_auto_merge_enabled
module Pull_request_closed = Terrat_github_webhooks_pull_request_closed
module Pull_request_converted_to_draft = Terrat_github_webhooks_pull_request_converted_to_draft
module Pull_request_edited = Terrat_github_webhooks_pull_request_edited
module Pull_request_labeled = Terrat_github_webhooks_pull_request_labeled
module Pull_request_locked = Terrat_github_webhooks_pull_request_locked
module Pull_request_milestoned = Terrat_github_webhooks_pull_request_milestoned
module Pull_request_opened = Terrat_github_webhooks_pull_request_opened
module Pull_request_ready_for_review = Terrat_github_webhooks_pull_request_ready_for_review
module Pull_request_reopened = Terrat_github_webhooks_pull_request_reopened

module Pull_request_review_request_removed =
  Terrat_github_webhooks_pull_request_review_request_removed

module Pull_request_review_requested = Terrat_github_webhooks_pull_request_review_requested
module Pull_request_synchronize = Terrat_github_webhooks_pull_request_synchronize
module Pull_request_unassigned = Terrat_github_webhooks_pull_request_unassigned
module Pull_request_unlabeled = Terrat_github_webhooks_pull_request_unlabeled
module Pull_request_unlocked = Terrat_github_webhooks_pull_request_unlocked
module Pull_request_event = Terrat_github_webhooks_pull_request_event
module Push_event = Terrat_github_webhooks_push_event
module Reactions = Terrat_github_webhooks_reactions
module Repo_ref = Terrat_github_webhooks_repo_ref
module Repository = Terrat_github_webhooks_repository
module Repository_lite = Terrat_github_webhooks_repository_lite
module Simple_pull_request = Terrat_github_webhooks_simple_pull_request
module Team = Terrat_github_webhooks_team
module User = Terrat_github_webhooks_user
module Workflow = Terrat_github_webhooks_workflow
module Workflow_job = Terrat_github_webhooks_workflow_job
module Workflow_run = Terrat_github_webhooks_workflow_run
module Workflow_step = Terrat_github_webhooks_workflow_step
module Workflow_step_completed = Terrat_github_webhooks_workflow_step_completed
module Workflow_step_in_progress = Terrat_github_webhooks_workflow_step_in_progress
module Workflow_step_pending = Terrat_github_webhooks_workflow_step_pending
module Workflow_step_queued = Terrat_github_webhooks_workflow_step_queued
module Workflow_dispatch_event = Terrat_github_webhooks_workflow_dispatch_event
module Workflow_job_completed = Terrat_github_webhooks_workflow_job_completed
module Workflow_job_in_progress = Terrat_github_webhooks_workflow_job_in_progress
module Workflow_job_queued = Terrat_github_webhooks_workflow_job_queued
module Workflow_job_event = Terrat_github_webhooks_workflow_job_event
module Workflow_run_completed = Terrat_github_webhooks_workflow_run_completed
module Workflow_run_in_progress = Terrat_github_webhooks_workflow_run_in_progress
module Workflow_run_requested = Terrat_github_webhooks_workflow_run_requested
module Workflow_run_event = Terrat_github_webhooks_workflow_run_event

module Event = struct
  type t =
    | Installation_event of Terrat_github_webhooks_installation_event.t
    | Installation_repositories_event of Terrat_github_webhooks_installation_repositories_event.t
    | Issue_comment_event of Terrat_github_webhooks_issue_comment_event.t
    | Pull_request_event of Terrat_github_webhooks_pull_request_event.t
    | Push_event of Terrat_github_webhooks_push_event.t
    | Workflow_dispatch_event of Terrat_github_webhooks_workflow_dispatch_event.t
    | Workflow_job_event of Terrat_github_webhooks_workflow_job_event.t
    | Workflow_run_event of Terrat_github_webhooks_workflow_run_event.t
  [@@deriving show]

  let of_yojson =
    Json_schema.one_of
      (let open CCResult in
      [
        (fun v ->
          map
            (fun v -> Installation_event v)
            (Terrat_github_webhooks_installation_event.of_yojson v));
        (fun v ->
          map
            (fun v -> Installation_repositories_event v)
            (Terrat_github_webhooks_installation_repositories_event.of_yojson v));
        (fun v ->
          map
            (fun v -> Issue_comment_event v)
            (Terrat_github_webhooks_issue_comment_event.of_yojson v));
        (fun v ->
          map
            (fun v -> Pull_request_event v)
            (Terrat_github_webhooks_pull_request_event.of_yojson v));
        (fun v -> map (fun v -> Push_event v) (Terrat_github_webhooks_push_event.of_yojson v));
        (fun v ->
          map
            (fun v -> Workflow_dispatch_event v)
            (Terrat_github_webhooks_workflow_dispatch_event.of_yojson v));
        (fun v ->
          map
            (fun v -> Workflow_job_event v)
            (Terrat_github_webhooks_workflow_job_event.of_yojson v));
        (fun v ->
          map
            (fun v -> Workflow_run_event v)
            (Terrat_github_webhooks_workflow_run_event.of_yojson v));
      ])

  let to_yojson = function
    | Installation_event v -> Terrat_github_webhooks_installation_event.to_yojson v
    | Installation_repositories_event v ->
        Terrat_github_webhooks_installation_repositories_event.to_yojson v
    | Issue_comment_event v -> Terrat_github_webhooks_issue_comment_event.to_yojson v
    | Pull_request_event v -> Terrat_github_webhooks_pull_request_event.to_yojson v
    | Push_event v -> Terrat_github_webhooks_push_event.to_yojson v
    | Workflow_dispatch_event v -> Terrat_github_webhooks_workflow_dispatch_event.to_yojson v
    | Workflow_job_event v -> Terrat_github_webhooks_workflow_job_event.to_yojson v
    | Workflow_run_event v -> Terrat_github_webhooks_workflow_run_event.to_yojson v
end
