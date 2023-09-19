type t =
  | Installation_work_manifest_drift of Terrat_api_components_installation_work_manifest_drift.t
  | Installation_work_manifest_pull_request of
      Terrat_api_components_installation_work_manifest_pull_request.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v ->
         map
           (fun v -> Installation_work_manifest_drift v)
           (Terrat_api_components_installation_work_manifest_drift.of_yojson v));
       (fun v ->
         map
           (fun v -> Installation_work_manifest_pull_request v)
           (Terrat_api_components_installation_work_manifest_pull_request.of_yojson v));
     ])

let to_yojson = function
  | Installation_work_manifest_drift v ->
      Terrat_api_components_installation_work_manifest_drift.to_yojson v
  | Installation_work_manifest_pull_request v ->
      Terrat_api_components_installation_work_manifest_pull_request.to_yojson v
