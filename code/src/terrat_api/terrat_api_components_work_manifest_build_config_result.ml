type t =
  | Work_manifest_build_config_result_success of
      Terrat_api_components_work_manifest_build_config_result_success.t
  | Work_manifest_build_config_result_failure of
      Terrat_api_components_work_manifest_build_config_result_failure.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v ->
         map
           (fun v -> Work_manifest_build_config_result_success v)
           (Terrat_api_components_work_manifest_build_config_result_success.of_yojson v));
       (fun v ->
         map
           (fun v -> Work_manifest_build_config_result_failure v)
           (Terrat_api_components_work_manifest_build_config_result_failure.of_yojson v));
     ])

let to_yojson = function
  | Work_manifest_build_config_result_success v ->
      Terrat_api_components_work_manifest_build_config_result_success.to_yojson v
  | Work_manifest_build_config_result_failure v ->
      Terrat_api_components_work_manifest_build_config_result_failure.to_yojson v
