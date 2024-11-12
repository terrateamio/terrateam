type t =
  | Workflow_step_output_scope_dirspace of
      Terrat_api_components_workflow_step_output_scope_dirspace.t
  | Workflow_step_output_scope_run of Terrat_api_components_workflow_step_output_scope_run.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v ->
         map
           (fun v -> Workflow_step_output_scope_dirspace v)
           (Terrat_api_components_workflow_step_output_scope_dirspace.of_yojson v));
       (fun v ->
         map
           (fun v -> Workflow_step_output_scope_run v)
           (Terrat_api_components_workflow_step_output_scope_run.of_yojson v));
     ])

let to_yojson = function
  | Workflow_step_output_scope_dirspace v ->
      Terrat_api_components_workflow_step_output_scope_dirspace.to_yojson v
  | Workflow_step_output_scope_run v ->
      Terrat_api_components_workflow_step_output_scope_run.to_yojson v
