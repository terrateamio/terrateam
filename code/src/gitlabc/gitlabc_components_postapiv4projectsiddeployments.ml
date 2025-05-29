module Primary = struct
  module Status = struct
    let t_of_yojson = function
      | `String "running" -> Ok "running"
      | `String "success" -> Ok "success"
      | `String "failed" -> Ok "failed"
      | `String "canceled" -> Ok "canceled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    environment : string;
    ref_ : string; [@key "ref"]
    sha : string;
    status : Status.t;
    tag : bool;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
