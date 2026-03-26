module Minimum_access_level_for_delete = struct
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

type t = {
  minimum_access_level_for_delete : Minimum_access_level_for_delete.t option; [@default None]
  minimum_access_level_for_push : Minimum_access_level_for_push.t option; [@default None]
  repository_path_pattern : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
