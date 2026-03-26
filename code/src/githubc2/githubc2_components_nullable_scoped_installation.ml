module Primary = struct
  module Repository_selection = struct
    let t_of_yojson = function
      | `String "all" -> Ok `All
      | `String "selected" -> Ok `Selected
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `All -> `String "all"
      | `Selected -> `String "selected"

    type t =
      ([ `All
       | `Selected
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Single_file_paths = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    account : Githubc2_components_simple_user.t;
    has_multiple_single_files : bool option; [@default None]
    permissions : Githubc2_components_app_permissions.t;
    repositories_url : string;
    repository_selection : Repository_selection.t;
    single_file_name : string option; [@default None]
    single_file_paths : Single_file_paths.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
