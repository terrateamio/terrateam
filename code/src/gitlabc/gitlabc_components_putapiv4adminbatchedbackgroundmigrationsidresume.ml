module Database = struct
  let t_of_yojson = function
    | `String "ci" -> Ok `Ci
    | `String "embedding" -> Ok `Embedding
    | `String "geo" -> Ok `Geo
    | `String "main" -> Ok `Main
    | `String "sec" -> Ok `Sec
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Ci -> `String "ci"
    | `Embedding -> `String "embedding"
    | `Geo -> `String "geo"
    | `Main -> `String "main"
    | `Sec -> `String "sec"

  type t =
    ([ `Ci
     | `Embedding
     | `Geo
     | `Main
     | `Sec
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { database : Database.t [@default `Main] }
[@@deriving yojson { strict = false; meta = true }, show, eq]
