module Primary = struct
  module Color = struct
    let t_of_yojson = function
      | `String "gray" -> Ok "gray"
      | `String "blue" -> Ok "blue"
      | `String "green" -> Ok "green"
      | `String "yellow" -> Ok "yellow"
      | `String "orange" -> Ok "orange"
      | `String "red" -> Ok "red"
      | `String "pink" -> Ok "pink"
      | `String "purple" -> Ok "purple"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    color : Color.t option; [@default None]
    created_at : string option; [@default None]
    description : string option; [@default None]
    id : int;
    is_enabled : bool option; [@default None]
    name : string;
    node_id : string;
    updated_at : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
