module Primary = struct
  module Repositories = struct
    type t = Githubc2_components_repository.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Repository_selection = struct
    let t_of_yojson = function
      | `String "all" -> Ok "all"
      | `String "selected" -> Ok "selected"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Single_file_paths = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    expires_at : string;
    has_multiple_single_files : bool option; [@default None]
    permissions : Githubc2_components_app_permissions.t option; [@default None]
    repositories : Repositories.t option; [@default None]
    repository_selection : Repository_selection.t option; [@default None]
    single_file : string option; [@default None]
    single_file_paths : Single_file_paths.t option; [@default None]
    token : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
