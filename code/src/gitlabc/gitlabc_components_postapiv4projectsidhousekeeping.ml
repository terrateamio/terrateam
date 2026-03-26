module Task = struct
  let t_of_yojson = function
    | `String "eager" -> Ok `Eager
    | `String "prune" -> Ok `Prune
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Eager -> `String "eager"
    | `Prune -> `String "prune"

  type t =
    ([ `Eager
     | `Prune
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { task : Task.t [@default `Eager] }
[@@deriving yojson { strict = false; meta = true }, show, eq]
