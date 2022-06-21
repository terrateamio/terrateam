type t =
  | Workflow_job_completed of Terrat_github_webhooks_workflow_job_completed.t
  | Workflow_job_in_progress of Terrat_github_webhooks_workflow_job_in_progress.t
  | Workflow_job_queued of Terrat_github_webhooks_workflow_job_queued.t
[@@deriving show]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
    [
      (fun v ->
        map
          (fun v -> Workflow_job_completed v)
          (Terrat_github_webhooks_workflow_job_completed.of_yojson v));
      (fun v ->
        map
          (fun v -> Workflow_job_in_progress v)
          (Terrat_github_webhooks_workflow_job_in_progress.of_yojson v));
      (fun v ->
        map
          (fun v -> Workflow_job_queued v)
          (Terrat_github_webhooks_workflow_job_queued.of_yojson v));
    ])

let to_yojson = function
  | Workflow_job_completed v -> Terrat_github_webhooks_workflow_job_completed.to_yojson v
  | Workflow_job_in_progress v -> Terrat_github_webhooks_workflow_job_in_progress.to_yojson v
  | Workflow_job_queued v -> Terrat_github_webhooks_workflow_job_queued.to_yojson v
