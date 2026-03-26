let t_of_yojson = function
  | `String "apply" -> Ok `Apply
  | `String "build-config" -> Ok `Build_config
  | `String "build-tree" -> Ok `Build_tree
  | `String "index" -> Ok `Index
  | `String "plan" -> Ok `Plan
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Apply -> `String "apply"
  | `Build_config -> `String "build-config"
  | `Build_tree -> `String "build-tree"
  | `Index -> `String "index"
  | `Plan -> `String "plan"

type t =
  ([ `Apply
   | `Build_config
   | `Build_tree
   | `Index
   | `Plan
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
