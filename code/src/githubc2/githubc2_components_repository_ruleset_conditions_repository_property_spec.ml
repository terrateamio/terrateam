module Primary = struct
  module Property_values = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Source = struct
    let t_of_yojson = function
      | `String "custom" -> Ok "custom"
      | `String "system" -> Ok "system"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    name : string;
    property_values : Property_values.t;
    source : Source.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
