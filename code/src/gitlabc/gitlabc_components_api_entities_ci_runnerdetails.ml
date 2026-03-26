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

type t = {
  access_level : string option; [@default None]
  active : bool option; [@default None]
  architecture : string option; [@default None]
  contacted_at : string option; [@default None]
  description : string option; [@default None]
  groups : Gitlabc_components_api_entities_basicgroupdetails.t option; [@default None]
  id : int option; [@default None]
  ip_address : string option; [@default None]
  is_shared : bool option; [@default None]
  locked : string option; [@default None]
  maintenance_note : string option; [@default None]
  maximum_timeout : string option; [@default None]
  name : string option; [@default None]
  online : bool option; [@default None]
  paused : bool option; [@default None]
  platform : string option; [@default None]
  projects : Gitlabc_components_api_entities_basicprojectdetails.t option; [@default None]
  revision : string option; [@default None]
  run_untagged : string option; [@default None]
  runner_type : Runner_type.t option; [@default None]
  status : string option; [@default None]
  tag_list : string option; [@default None]
  version : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
