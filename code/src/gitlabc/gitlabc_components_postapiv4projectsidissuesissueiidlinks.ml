module Link_type = struct
  let t_of_yojson = function
    | `String "relates_to" -> Ok "relates_to"
    | `String "blocks" -> Ok "blocks"
    | `String "is_blocked_by" -> Ok "is_blocked_by"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  link_type : Link_type.t option; [@default None]
  target_issue_iid : string;
  target_project_id : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
