module Primary = struct
  module Role = struct
    let t_of_yojson = function
      | `String "member" -> Ok "member"
      | `String "maintainer" -> Ok "maintainer"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module State = struct
    let t_of_yojson = function
      | `String "active" -> Ok "active"
      | `String "pending" -> Ok "pending"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    role : Role.t; [@default "member"]
    state : State.t;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
