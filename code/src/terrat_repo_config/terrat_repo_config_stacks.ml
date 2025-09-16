module Names = struct
  module Additional = struct
    type t =
      | Stack_config of Terrat_repo_config_stack_config.t
      | Stack_nested_config of Terrat_repo_config_stack_nested_config.t
    [@@deriving show, eq]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
         [
           (fun v -> map (fun v -> Stack_config v) (Terrat_repo_config_stack_config.of_yojson v));
           (fun v ->
             map
               (fun v -> Stack_nested_config v)
               (Terrat_repo_config_stack_nested_config.of_yojson v));
         ])

    let to_yojson = function
      | Stack_config v -> Terrat_repo_config_stack_config.to_yojson v
      | Stack_nested_config v -> Terrat_repo_config_stack_nested_config.to_yojson v
  end

  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
end

type t = { names : Names.t option [@default None] }
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
