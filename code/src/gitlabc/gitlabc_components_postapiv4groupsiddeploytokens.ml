module Scopes = struct
  module Items = struct
    let t_of_yojson = function
      | `String "read_repository" -> Ok "read_repository"
      | `String "read_registry" -> Ok "read_registry"
      | `String "write_registry" -> Ok "write_registry"
      | `String "read_package_registry" -> Ok "read_package_registry"
      | `String "write_package_registry" -> Ok "write_package_registry"
      | `String "read_virtual_registry" -> Ok "read_virtual_registry"
      | `String "write_virtual_registry" -> Ok "write_virtual_registry"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  expires_at : string option; [@default None]
  name : string;
  scopes : Scopes.t;
  username : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
