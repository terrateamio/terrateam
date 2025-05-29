module Primary = struct
  module Line_type = struct
    let t_of_yojson = function
      | `String "new" -> Ok "new"
      | `String "old" -> Ok "old"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    line : int;
    line_type : Line_type.t; [@default "new"]
    note : string;
    path : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
