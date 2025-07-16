module Access_level = struct
  let t_of_yojson = function
    | `String "not_protected" -> Ok "not_protected"
    | `String "ref_protected" -> Ok "ref_protected"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Info = struct
  module Primary = struct
    type t = {
      architecture : string option; [@default None]
      name : string option; [@default None]
      platform : string option; [@default None]
      revision : string option; [@default None]
      version : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Tag_list = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  access_level : Access_level.t option; [@default None]
  active : bool option; [@default None]
  description : string option; [@default None]
  info : Info.t option; [@default None]
  locked : bool option; [@default None]
  maintainer_note : string option; [@default None]
  maintenance_note : string option; [@default None]
  maximum_timeout : int option; [@default None]
  paused : bool option; [@default None]
  run_untagged : bool option; [@default None]
  tag_list : Tag_list.t option; [@default None]
  token : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
