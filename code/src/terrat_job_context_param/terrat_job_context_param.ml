module Branch = Terrat_job_context_param_branch
module Branch_dest_branch = Terrat_job_context_param_branch_dest_branch
module Context = Terrat_job_context_param_context
module Pull_request = Terrat_job_context_param_pull_request

module Event = struct
  type t = Context of Terrat_job_context_param_context.t [@@deriving show, eq]

  let of_yojson =
    Json_schema.one_of
      (let open CCResult in
       [ (fun v -> map (fun v -> Context v) (Terrat_job_context_param_context.of_yojson v)) ])

  let to_yojson = function
    | Context v -> Terrat_job_context_param_context.to_yojson v
end
