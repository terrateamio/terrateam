module Primary = struct
  module Source = struct
    let t_of_yojson = function
      | `String "github" -> Ok "github"
      | `String "partner" -> Ok "partner"
      | `String "custom" -> Ok "custom"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    display_name : string;
    id : string;
    size_gb : int;
    source : Source.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
