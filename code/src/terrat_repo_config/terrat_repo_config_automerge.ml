module Merge_strategy = struct
  let t_of_yojson = function
    | `String "auto" -> Ok "auto"
    | `String "merge" -> Ok "merge"
    | `String "rebase" -> Ok "rebase"
    | `String "squash" -> Ok "squash"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  delete_branch : bool; [@default false]
  enabled : bool; [@default false]
  merge_strategy : Merge_strategy.t; [@default "auto"]
  require_explicit_apply : bool; [@default false]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
