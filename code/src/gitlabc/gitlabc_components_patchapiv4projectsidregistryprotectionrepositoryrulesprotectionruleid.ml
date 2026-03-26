module Minimum_access_level_for_delete = struct
  let t_of_yojson = function
    | `String "" -> Ok `Empty
    | `String "admin" -> Ok `Admin
    | `String "maintainer" -> Ok `Maintainer
    | `String "owner" -> Ok `Owner
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Empty -> `String ""
    | `Admin -> `String "admin"
    | `Maintainer -> `String "maintainer"
    | `Owner -> `String "owner"

  type t =
    ([ `Empty
     | `Admin
     | `Maintainer
     | `Owner
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Minimum_access_level_for_push = struct
  let t_of_yojson = function
    | `String "" -> Ok `Empty
    | `String "admin" -> Ok `Admin
    | `String "maintainer" -> Ok `Maintainer
    | `String "owner" -> Ok `Owner
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Empty -> `String ""
    | `Admin -> `String "admin"
    | `Maintainer -> `String "maintainer"
    | `Owner -> `String "owner"

  type t =
    ([ `Empty
     | `Admin
     | `Maintainer
     | `Owner
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  minimum_access_level_for_delete : Minimum_access_level_for_delete.t option; [@default None]
  minimum_access_level_for_push : Minimum_access_level_for_push.t option; [@default None]
  repository_path_pattern : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
