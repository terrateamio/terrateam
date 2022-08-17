module Primary = struct
  module Type = struct
    let t_of_yojson = function
      | `String "read-only" -> Ok "read-only"
      | `String "custom" -> Ok "custom"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    id : int option; [@default None]
    name : string;
    type_ : Type.t option; [@default None] [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
