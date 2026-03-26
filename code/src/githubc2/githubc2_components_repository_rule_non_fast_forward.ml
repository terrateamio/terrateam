module Primary = struct
  module Type = struct
    let t_of_yojson = function
      | `String "non_fast_forward" -> Ok `Non_fast_forward
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Non_fast_forward -> `String "non_fast_forward"

    type t = ([ `Non_fast_forward ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = { type_ : Type.t [@key "type"] }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
