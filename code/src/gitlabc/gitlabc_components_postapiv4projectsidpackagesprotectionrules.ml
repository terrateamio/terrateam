module Minimum_access_level_for_push = struct
  let t_of_yojson = function
    | `String "maintainer" -> Ok "maintainer"
    | `String "owner" -> Ok "owner"
    | `String "admin" -> Ok "admin"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Package_type = struct
  let t_of_yojson = function
    | `String "conan" -> Ok "conan"
    | `String "maven" -> Ok "maven"
    | `String "npm" -> Ok "npm"
    | `String "pypi" -> Ok "pypi"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  minimum_access_level_for_push : Minimum_access_level_for_push.t;
  package_name_pattern : string;
  package_type : Package_type.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
