module Database = struct
  let t_of_yojson = function
    | `String "main" -> Ok "main"
    | `String "ci" -> Ok "ci"
    | `String "sec" -> Ok "sec"
    | `String "embedding" -> Ok "embedding"
    | `String "geo" -> Ok "geo"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { database : Database.t [@default "main"] }
[@@deriving yojson { strict = false; meta = true }, show, eq]
