module Process_mode = struct
  let t_of_yojson = function
    | `String "newest_first" -> Ok `Newest_first
    | `String "oldest_first" -> Ok `Oldest_first
    | `String "unordered" -> Ok `Unordered
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Newest_first -> `String "newest_first"
    | `Oldest_first -> `String "oldest_first"
    | `Unordered -> `String "unordered"

  type t =
    ([ `Newest_first
     | `Oldest_first
     | `Unordered
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { process_mode : Process_mode.t option [@default None] }
[@@deriving yojson { strict = false; meta = true }, show, eq]
