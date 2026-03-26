module Primary = struct
  module State = struct
    let t_of_yojson = function
      | `String "active" -> Ok `Active
      | `String "deleted" -> Ok `Deleted
      | `String "disabled_fork" -> Ok `Disabled_fork
      | `String "disabled_inactivity" -> Ok `Disabled_inactivity
      | `String "disabled_manually" -> Ok `Disabled_manually
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Active -> `String "active"
      | `Deleted -> `String "deleted"
      | `Disabled_fork -> `String "disabled_fork"
      | `Disabled_inactivity -> `String "disabled_inactivity"
      | `Disabled_manually -> `String "disabled_manually"

    type t =
      ([ `Active
       | `Deleted
       | `Disabled_fork
       | `Disabled_inactivity
       | `Disabled_manually
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
