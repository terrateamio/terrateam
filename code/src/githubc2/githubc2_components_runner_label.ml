module Primary = struct
  module Type = struct
    let t_of_yojson = function
      | `String "custom" -> Ok `Custom
      | `String "read-only" -> Ok `Read_only
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Custom -> `String "custom"
      | `Read_only -> `String "read-only"

    type t =
      ([ `Custom
       | `Read_only
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    id : int option; [@default None]
    name : string;
    type_ : Type.t option; [@default None] [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
