module Process_mode = struct
  let t_of_yojson = function
    | `String "unordered" -> Ok "unordered"
    | `String "oldest_first" -> Ok "oldest_first"
    | `String "newest_first" -> Ok "newest_first"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { process_mode : Process_mode.t option [@default None] }
[@@deriving yojson { strict = false; meta = true }, show, eq]
