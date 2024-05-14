type t =
  | Apply_requirements_checks_1 of Terrat_repo_config_apply_requirements_checks_1.t
  | Apply_requirements_checks_2 of Terrat_repo_config_apply_requirements_checks_2.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v ->
         map
           (fun v -> Apply_requirements_checks_1 v)
           (Terrat_repo_config_apply_requirements_checks_1.of_yojson v));
       (fun v ->
         map
           (fun v -> Apply_requirements_checks_2 v)
           (Terrat_repo_config_apply_requirements_checks_2.of_yojson v));
     ])

let to_yojson = function
  | Apply_requirements_checks_1 v -> Terrat_repo_config_apply_requirements_checks_1.to_yojson v
  | Apply_requirements_checks_2 v -> Terrat_repo_config_apply_requirements_checks_2.to_yojson v
