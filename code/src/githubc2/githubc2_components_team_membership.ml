module Primary = struct
  module Role = struct
    let t_of_yojson = function
      | `String "maintainer" -> Ok `Maintainer
      | `String "member" -> Ok `Member
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Maintainer -> `String "maintainer"
      | `Member -> `String "member"

    type t =
      ([ `Maintainer
       | `Member
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module State = struct
    let t_of_yojson = function
      | `String "active" -> Ok `Active
      | `String "pending" -> Ok `Pending
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Active -> `String "active"
      | `Pending -> `String "pending"

    type t =
      ([ `Active
       | `Pending
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    role : Role.t; [@default `Member]
    state : State.t;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
