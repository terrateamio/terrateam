module Dirspaces = struct
  type t = Terrat_api_components_work_manifest_dirspace.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Kind = struct
  type t =
    | Kind_drift of Terrat_api_components_kind_drift.t
    | Kind_index of Terrat_api_components_kind_index.t
    | Kind_pull_request of Terrat_api_components_kind_pull_request.t
  [@@deriving show, eq]

  let of_yojson =
    Json_schema.one_of
      (let open CCResult in
       [
         (fun v -> map (fun v -> Kind_drift v) (Terrat_api_components_kind_drift.of_yojson v));
         (fun v -> map (fun v -> Kind_index v) (Terrat_api_components_kind_index.of_yojson v));
         (fun v ->
           map (fun v -> Kind_pull_request v) (Terrat_api_components_kind_pull_request.of_yojson v));
       ])

  let to_yojson = function
    | Kind_drift v -> Terrat_api_components_kind_drift.to_yojson v
    | Kind_index v -> Terrat_api_components_kind_index.to_yojson v
    | Kind_pull_request v -> Terrat_api_components_kind_pull_request.to_yojson v
end

type t = {
  base_branch : string;
  base_ref : string;
  branch : string;
  branch_ref : string;
  completed_at : string option; [@default None]
  created_at : string;
  dirspaces : Dirspaces.t;
  environment : string option; [@default None]
  id : string;
  kind : Kind.t;
  owner : string;
  repo : string;
  run_id : string option; [@default None]
  run_type : Terrat_api_components_run_type.t;
  state : Terrat_api_components_work_manifest_state.t;
  tag_query : string;
  user : string option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, show, eq]
