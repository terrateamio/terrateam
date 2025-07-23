module Comment_strategy = struct
  let t_of_yojson = function
    | `String "append" -> Ok "append"
    | `String "delete" -> Ok "delete"
    | `String "minimize" -> Ok "minimize"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  comment_strategy : Comment_strategy.t; [@default "append"]
  tag_query : string;
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
