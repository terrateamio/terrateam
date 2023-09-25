module Primary = struct
  module State = struct
    let t_of_yojson = function
      | `String "approved" -> Ok "approved"
      | `String "rejected" -> Ok "rejected"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    comment : string option; [@default None]
    environment_name : string;
    state : State.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
