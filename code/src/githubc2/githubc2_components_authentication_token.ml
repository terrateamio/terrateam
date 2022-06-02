module Primary = struct
  module Permissions = struct
    include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
  end

  module Repositories = struct
    type t = Githubc2_components_repository.t list
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Repository_selection = struct
    let t_of_yojson = function
      | `String "all" -> Ok "all"
      | `String "selected" -> Ok "selected"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    expires_at : string;
    permissions : Permissions.t option; [@default None]
    repositories : Repositories.t option; [@default None]
    repository_selection : Repository_selection.t option; [@default None]
    single_file : string option; [@default None]
    token : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
