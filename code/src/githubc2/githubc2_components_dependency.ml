module Dependencies = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Relationship = struct
  let t_of_yojson = function
    | `String "direct" -> Ok `Direct
    | `String "indirect" -> Ok `Indirect
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Direct -> `String "direct"
    | `Indirect -> `String "indirect"

  type t =
    ([ `Direct
     | `Indirect
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Scope = struct
  let t_of_yojson = function
    | `String "development" -> Ok `Development
    | `String "runtime" -> Ok `Runtime
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Development -> `String "development"
    | `Runtime -> `String "runtime"

  type t =
    ([ `Development
     | `Runtime
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  dependencies : Dependencies.t option; [@default None]
  metadata : Githubc2_components_metadata.t option; [@default None]
  package_url : string option; [@default None]
  relationship : Relationship.t option; [@default None]
  scope : Scope.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
