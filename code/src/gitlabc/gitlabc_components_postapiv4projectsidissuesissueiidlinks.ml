module Link_type = struct
  let t_of_yojson = function
    | `String "blocks" -> Ok `Blocks
    | `String "is_blocked_by" -> Ok `Is_blocked_by
    | `String "relates_to" -> Ok `Relates_to
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Blocks -> `String "blocks"
    | `Is_blocked_by -> `String "is_blocked_by"
    | `Relates_to -> `String "relates_to"

  type t =
    ([ `Blocks
     | `Is_blocked_by
     | `Relates_to
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  link_type : Link_type.t option; [@default None]
  target_issue_iid : string;
  target_project_id : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
