module Merge_strategy = struct
  let t_of_yojson = function
    | `String "auto" -> Ok `Auto
    | `String "merge" -> Ok `Merge
    | `String "rebase" -> Ok `Rebase
    | `String "squash" -> Ok `Squash
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Auto -> `String "auto"
    | `Merge -> `String "merge"
    | `Rebase -> `String "rebase"
    | `Squash -> `String "squash"

  type t =
    ([ `Auto
     | `Merge
     | `Rebase
     | `Squash
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  delete_branch : bool; [@default false]
  enabled : bool; [@default false]
  merge_strategy : Merge_strategy.t; [@default `Auto]
  require_explicit_apply : bool; [@default false]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
