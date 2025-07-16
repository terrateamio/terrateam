module Task = struct
  let t_of_yojson = function
    | `String "eager" -> Ok "eager"
    | `String "prune" -> Ok "prune"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { task : Task.t [@default "eager"] }
[@@deriving yojson { strict = false; meta = true }, show, eq]
