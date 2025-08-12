type t =
  | Work_manifest_plan of Terrat_api_components_work_manifest_plan.t
  | Work_manifest_apply of Terrat_api_components_work_manifest_apply.t
  | Work_manifest_index of Terrat_api_components_work_manifest_index.t
  | Work_manifest_unsafe_apply of Terrat_api_components_work_manifest_unsafe_apply.t
  | Work_manifest_build_config of Terrat_api_components_work_manifest_build_config.t
  | Work_manifest_done of Terrat_api_components_work_manifest_done.t
  | Work_manifest_build_tree of Terrat_api_components_work_manifest_build_tree.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v ->
         map (fun v -> Work_manifest_plan v) (Terrat_api_components_work_manifest_plan.of_yojson v));
       (fun v ->
         map
           (fun v -> Work_manifest_apply v)
           (Terrat_api_components_work_manifest_apply.of_yojson v));
       (fun v ->
         map
           (fun v -> Work_manifest_index v)
           (Terrat_api_components_work_manifest_index.of_yojson v));
       (fun v ->
         map
           (fun v -> Work_manifest_unsafe_apply v)
           (Terrat_api_components_work_manifest_unsafe_apply.of_yojson v));
       (fun v ->
         map
           (fun v -> Work_manifest_build_config v)
           (Terrat_api_components_work_manifest_build_config.of_yojson v));
       (fun v ->
         map (fun v -> Work_manifest_done v) (Terrat_api_components_work_manifest_done.of_yojson v));
       (fun v ->
         map
           (fun v -> Work_manifest_build_tree v)
           (Terrat_api_components_work_manifest_build_tree.of_yojson v));
     ])

let to_yojson = function
  | Work_manifest_plan v -> Terrat_api_components_work_manifest_plan.to_yojson v
  | Work_manifest_apply v -> Terrat_api_components_work_manifest_apply.to_yojson v
  | Work_manifest_index v -> Terrat_api_components_work_manifest_index.to_yojson v
  | Work_manifest_unsafe_apply v -> Terrat_api_components_work_manifest_unsafe_apply.to_yojson v
  | Work_manifest_build_config v -> Terrat_api_components_work_manifest_build_config.to_yojson v
  | Work_manifest_done v -> Terrat_api_components_work_manifest_done.to_yojson v
  | Work_manifest_build_tree v -> Terrat_api_components_work_manifest_build_tree.to_yojson v
