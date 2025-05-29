module Primary = struct
  module Minimum_access_level_for_delete = struct
    let t_of_yojson = function
      | `String "maintainer" -> Ok "maintainer"
      | `String "owner" -> Ok "owner"
      | `String "admin" -> Ok "admin"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Minimum_access_level_for_push = struct
    let t_of_yojson = function
      | `String "maintainer" -> Ok "maintainer"
      | `String "owner" -> Ok "owner"
      | `String "admin" -> Ok "admin"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    minimum_access_level_for_delete : Minimum_access_level_for_delete.t option; [@default None]
    minimum_access_level_for_push : Minimum_access_level_for_push.t option; [@default None]
    repository_path_pattern : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
