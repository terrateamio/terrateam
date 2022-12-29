module Items = struct
  type t =
    | Workflow_output_run of Terrat_api_components_workflow_output_run.t
    | Workflow_output_env of Terrat_api_components_workflow_output_env.t
    | Workflow_output_init of Terrat_api_components_workflow_output_init.t
    | Workflow_output_plan of Terrat_api_components_workflow_output_plan.t
    | Workflow_output_apply of Terrat_api_components_workflow_output_apply.t
  [@@deriving show, eq]

  let of_yojson =
    Json_schema.one_of
      (let open CCResult in
      [
        (fun v ->
          map
            (fun v -> Workflow_output_run v)
            (Terrat_api_components_workflow_output_run.of_yojson v));
        (fun v ->
          map
            (fun v -> Workflow_output_env v)
            (Terrat_api_components_workflow_output_env.of_yojson v));
        (fun v ->
          map
            (fun v -> Workflow_output_init v)
            (Terrat_api_components_workflow_output_init.of_yojson v));
        (fun v ->
          map
            (fun v -> Workflow_output_plan v)
            (Terrat_api_components_workflow_output_plan.of_yojson v));
        (fun v ->
          map
            (fun v -> Workflow_output_apply v)
            (Terrat_api_components_workflow_output_apply.of_yojson v));
      ])

  let to_yojson = function
    | Workflow_output_run v -> Terrat_api_components_workflow_output_run.to_yojson v
    | Workflow_output_env v -> Terrat_api_components_workflow_output_env.to_yojson v
    | Workflow_output_init v -> Terrat_api_components_workflow_output_init.to_yojson v
    | Workflow_output_plan v -> Terrat_api_components_workflow_output_plan.to_yojson v
    | Workflow_output_apply v -> Terrat_api_components_workflow_output_apply.to_yojson v
end

type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
