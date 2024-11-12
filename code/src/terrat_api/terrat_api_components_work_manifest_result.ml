type t =
  | Work_manifest_index_result of Terrat_api_components_work_manifest_index_result.t
  | Work_manifest_build_config_result of Terrat_api_components_work_manifest_build_config_result.t
  | Work_manifest_tf_operation_result of Terrat_api_components_work_manifest_tf_operation_result.t
  | Work_manifest_tf_operation_result2 of Terrat_api_components_work_manifest_tf_operation_result2.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v ->
         map
           (fun v -> Work_manifest_index_result v)
           (Terrat_api_components_work_manifest_index_result.of_yojson v));
       (fun v ->
         map
           (fun v -> Work_manifest_build_config_result v)
           (Terrat_api_components_work_manifest_build_config_result.of_yojson v));
       (fun v ->
         map
           (fun v -> Work_manifest_tf_operation_result v)
           (Terrat_api_components_work_manifest_tf_operation_result.of_yojson v));
       (fun v ->
         map
           (fun v -> Work_manifest_tf_operation_result2 v)
           (Terrat_api_components_work_manifest_tf_operation_result2.of_yojson v));
     ])

let to_yojson = function
  | Work_manifest_index_result v -> Terrat_api_components_work_manifest_index_result.to_yojson v
  | Work_manifest_build_config_result v ->
      Terrat_api_components_work_manifest_build_config_result.to_yojson v
  | Work_manifest_tf_operation_result v ->
      Terrat_api_components_work_manifest_tf_operation_result.to_yojson v
  | Work_manifest_tf_operation_result2 v ->
      Terrat_api_components_work_manifest_tf_operation_result2.to_yojson v
