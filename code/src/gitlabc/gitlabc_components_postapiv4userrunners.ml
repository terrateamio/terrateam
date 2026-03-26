module Access_level = struct
  let t_of_yojson = function
    | `String "not_protected" -> Ok `Not_protected
    | `String "ref_protected" -> Ok `Ref_protected
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Not_protected -> `String "not_protected"
    | `Ref_protected -> `String "ref_protected"

  type t =
    ([ `Not_protected
     | `Ref_protected
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Runner_type = struct
  let t_of_yojson = function
    | `String "group_type" -> Ok `Group_type
    | `String "instance_type" -> Ok `Instance_type
    | `String "project_type" -> Ok `Project_type
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Group_type -> `String "group_type"
    | `Instance_type -> `String "instance_type"
    | `Project_type -> `String "project_type"

  type t =
    ([ `Group_type
     | `Instance_type
     | `Project_type
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Tag_list = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  access_level : Access_level.t option; [@default None]
  description : string option; [@default None]
  group_id : int;
  locked : bool option; [@default None]
  maintenance_note : string option; [@default None]
  maximum_timeout : int option; [@default None]
  paused : bool option; [@default None]
  project_id : int;
  run_untagged : bool option; [@default None]
  runner_type : Runner_type.t;
  tag_list : Tag_list.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
