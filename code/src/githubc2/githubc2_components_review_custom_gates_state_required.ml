module Primary = struct
  module State = struct
    let t_of_yojson = function
      | `String "approved" -> Ok `Approved
      | `String "rejected" -> Ok `Rejected
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Approved -> `String "approved"
      | `Rejected -> `String "rejected"

    type t =
      ([ `Approved
       | `Rejected
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
