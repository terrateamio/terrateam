type t =
  | Work_manifest_plan of Terrat_api_components_work_manifest_plan.t
  | Work_manifest_apply of Terrat_api_components_work_manifest_apply.t
[@@deriving show]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
    [
      (fun v ->
        map (fun v -> Work_manifest_plan v) (Terrat_api_components_work_manifest_plan.of_yojson v));
      (fun v ->
        map (fun v -> Work_manifest_apply v) (Terrat_api_components_work_manifest_apply.of_yojson v));
    ])

let to_yojson = function
  | Work_manifest_plan v -> Terrat_api_components_work_manifest_plan.to_yojson v
  | Work_manifest_apply v -> Terrat_api_components_work_manifest_apply.to_yojson v
