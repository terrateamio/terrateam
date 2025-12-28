type t =
  | Pull_request of Terrat_job_context_param_pull_request.t
  | Branch of Terrat_job_context_param_branch.t
  | Branch_dest_branch of Terrat_job_context_param_branch_dest_branch.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v -> map (fun v -> Pull_request v) (Terrat_job_context_param_pull_request.of_yojson v));
       (fun v -> map (fun v -> Branch v) (Terrat_job_context_param_branch.of_yojson v));
       (fun v ->
         map
           (fun v -> Branch_dest_branch v)
           (Terrat_job_context_param_branch_dest_branch.of_yojson v));
     ])

let to_yojson = function
  | Pull_request v -> Terrat_job_context_param_pull_request.to_yojson v
  | Branch v -> Terrat_job_context_param_branch.to_yojson v
  | Branch_dest_branch v -> Terrat_job_context_param_branch_dest_branch.to_yojson v
