module Comment_strategy = struct
  let t_of_yojson = function
    | `String "append" -> Ok `Append
    | `String "delete" -> Ok `Delete
    | `String "minimize" -> Ok `Minimize
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Append -> `String "append"
    | `Delete -> `String "delete"
    | `Minimize -> `String "minimize"

  type t =
    ([ `Append
     | `Delete
     | `Minimize
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  comment_strategy : Comment_strategy.t; [@default `Minimize]
  tag_query : string;
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
