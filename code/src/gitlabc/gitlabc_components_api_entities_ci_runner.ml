module Runner_type = struct
  let t_of_yojson = function
    | `String "instance_type" -> Ok "instance_type"
    | `String "group_type" -> Ok "group_type"
    | `String "project_type" -> Ok "project_type"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  active : bool option; [@default None]
  description : string option; [@default None]
  id : int option; [@default None]
  ip_address : string option; [@default None]
  is_shared : bool option; [@default None]
  name : string option; [@default None]
  online : bool option; [@default None]
  paused : bool option; [@default None]
  runner_type : Runner_type.t option; [@default None]
  status : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
