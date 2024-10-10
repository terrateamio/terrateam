module Payload = struct
  module Additional = struct
    type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
end

module Scope = struct
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
end

type t = {
  ignore_errors : bool;
  payload : Payload.t;
  scope : Scope.t;
  step : string;
  success : bool;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]
