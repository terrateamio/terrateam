module Primary = struct
  module Status_ = struct
    let t_of_yojson = function
      | `String "AT_RISK" -> Ok `AT_RISK
      | `String "COMPLETE" -> Ok `COMPLETE
      | `String "INACTIVE" -> Ok `INACTIVE
      | `String "OFF_TRACK" -> Ok `OFF_TRACK
      | `String "ON_TRACK" -> Ok `ON_TRACK
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `AT_RISK -> `String "AT_RISK"
      | `COMPLETE -> `String "COMPLETE"
      | `INACTIVE -> `String "INACTIVE"
      | `OFF_TRACK -> `String "OFF_TRACK"
      | `ON_TRACK -> `String "ON_TRACK"

    type t =
      ([ `AT_RISK
       | `COMPLETE
       | `INACTIVE
       | `OFF_TRACK
       | `ON_TRACK
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
