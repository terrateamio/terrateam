module Primary = struct
  module Status_ = struct
    let t_of_yojson = function
      | `String "INACTIVE" -> Ok "INACTIVE"
      | `String "ON_TRACK" -> Ok "ON_TRACK"
      | `String "AT_RISK" -> Ok "AT_RISK"
      | `String "OFF_TRACK" -> Ok "OFF_TRACK"
      | `String "COMPLETE" -> Ok "COMPLETE"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    body : string option; [@default None]
    created_at : string;
    creator : Githubc2_components_simple_user.t option; [@default None]
    id : float;
    node_id : string;
    project_node_id : string option; [@default None]
    start_date : string option; [@default None]
    status : Status_.t option; [@default None]
    target_date : string option; [@default None]
    updated_at : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
