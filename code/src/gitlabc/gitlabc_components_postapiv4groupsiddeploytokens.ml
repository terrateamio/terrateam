module Scopes = struct
  module Items = struct
    let t_of_yojson = function
      | `String "read_package_registry" -> Ok `Read_package_registry
      | `String "read_registry" -> Ok `Read_registry
      | `String "read_repository" -> Ok `Read_repository
      | `String "read_virtual_registry" -> Ok `Read_virtual_registry
      | `String "write_package_registry" -> Ok `Write_package_registry
      | `String "write_registry" -> Ok `Write_registry
      | `String "write_virtual_registry" -> Ok `Write_virtual_registry
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Read_package_registry -> `String "read_package_registry"
      | `Read_registry -> `String "read_registry"
      | `Read_repository -> `String "read_repository"
      | `Read_virtual_registry -> `String "read_virtual_registry"
      | `Write_package_registry -> `String "write_package_registry"
      | `Write_registry -> `String "write_registry"
      | `Write_virtual_registry -> `String "write_virtual_registry"

    type t =
      ([ `Read_package_registry
       | `Read_registry
       | `Read_repository
       | `Read_virtual_registry
       | `Write_package_registry
       | `Write_registry
       | `Write_virtual_registry
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
