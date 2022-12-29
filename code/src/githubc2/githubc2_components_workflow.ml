module Primary = struct
  module State = struct
    let t_of_yojson = function
      | `String "active" -> Ok "active"
      | `String "deleted" -> Ok "deleted"
      | `String "disabled_fork" -> Ok "disabled_fork"
      | `String "disabled_inactivity" -> Ok "disabled_inactivity"
      | `String "disabled_manually" -> Ok "disabled_manually"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    badge_url : string;
    created_at : string;
    deleted_at : string option; [@default None]
    html_url : string;
    id : int;
    name : string;
    node_id : string;
    path : string;
    state : State.t;
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
