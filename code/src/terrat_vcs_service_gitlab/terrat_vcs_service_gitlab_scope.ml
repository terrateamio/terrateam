module Scope = struct
  type t =
    | Dirspace of Terrat_dirspace.t
    | Run of {
        flow : string;
        subflow : string;
      }
  [@@deriving eq, ord]

  let of_terrat_api_scope =
    let module S = Terrat_api_components.Workflow_step_output_scope in
    let module Ds = Terrat_api_components.Workflow_step_output_scope_dirspace in
    let module R = Terrat_api_components.Workflow_step_output_scope_run in
    function
    | S.Workflow_step_output_scope_dirspace { Ds.dir; workspace; _ } ->
        Dirspace { Terrat_dirspace.dir; workspace }
    | S.Workflow_step_output_scope_run { R.flow; subflow; _ } -> Run { flow; subflow }
end

module By_scope = Terrat_data.Group_by (struct
  module T = Terrat_api_components.Workflow_step_output

  type t = T.t
  type key = Scope.t

  let compare = Scope.compare
  let key { T.scope; _ } = Scope.of_terrat_api_scope scope
end)
