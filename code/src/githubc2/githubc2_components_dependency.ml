module Dependencies = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Relationship = struct
  let t_of_yojson = function
    | `String "direct" -> Ok "direct"
    | `String "indirect" -> Ok "indirect"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Scope = struct
  let t_of_yojson = function
    | `String "runtime" -> Ok "runtime"
    | `String "development" -> Ok "development"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  dependencies : Dependencies.t option; [@default None]
  metadata : Githubc2_components_metadata.t option; [@default None]
  package_url : string option; [@default None]
  relationship : Relationship.t option; [@default None]
  scope : Scope.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, show, eq]
