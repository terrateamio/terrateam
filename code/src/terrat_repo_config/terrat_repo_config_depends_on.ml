type t =
  | Depends_on_tag_query of Terrat_repo_config_depends_on_tag_query.t
  | Depends_on_object of Terrat_repo_config_depends_on_object.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v ->
         map (fun v -> Depends_on_tag_query v) (Terrat_repo_config_depends_on_tag_query.of_yojson v));
       (fun v ->
         map (fun v -> Depends_on_object v) (Terrat_repo_config_depends_on_object.of_yojson v));
     ])

let to_yojson = function
  | Depends_on_tag_query v -> Terrat_repo_config_depends_on_tag_query.to_yojson v
  | Depends_on_object v -> Terrat_repo_config_depends_on_object.to_yojson v
