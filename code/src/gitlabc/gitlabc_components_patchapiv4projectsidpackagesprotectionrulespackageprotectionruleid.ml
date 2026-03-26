module Minimum_access_level_for_push = struct
  let t_of_yojson = function
    | `String "admin" -> Ok `Admin
    | `String "maintainer" -> Ok `Maintainer
    | `String "owner" -> Ok `Owner
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Admin -> `String "admin"
    | `Maintainer -> `String "maintainer"
    | `Owner -> `String "owner"

  type t =
    ([ `Admin
     | `Maintainer
     | `Owner
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Package_type = struct
  let t_of_yojson = function
    | `String "conan" -> Ok `Conan
    | `String "maven" -> Ok `Maven
    | `String "npm" -> Ok `Npm
    | `String "pypi" -> Ok `Pypi
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Conan -> `String "conan"
    | `Maven -> `String "maven"
    | `Npm -> `String "npm"
    | `Pypi -> `String "pypi"

  type t =
    ([ `Conan
     | `Maven
     | `Npm
     | `Pypi
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  minimum_access_level_for_push : Minimum_access_level_for_push.t option; [@default None]
  package_name_pattern : string option; [@default None]
  package_type : Package_type.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
