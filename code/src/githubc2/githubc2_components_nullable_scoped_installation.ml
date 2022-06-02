module Primary = struct
  module Repository_selection = struct
    let t_of_yojson = function
      | `String "all" -> Ok "all"
      | `String "selected" -> Ok "selected"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Single_file_paths = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    account : Githubc2_components_simple_user.t;
    has_multiple_single_files : bool option; [@default None]
    permissions : Githubc2_components_app_permissions.t;
    repositories_url : string;
    repository_selection : Repository_selection.t;
    single_file_name : string option;
    single_file_paths : Single_file_paths.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
