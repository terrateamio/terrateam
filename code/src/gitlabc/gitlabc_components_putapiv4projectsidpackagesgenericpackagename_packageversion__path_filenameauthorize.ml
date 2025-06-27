module Primary = struct
  module Status = struct
    let t_of_yojson = function
      | `String "default" -> Ok "default"
      | `String "hidden" -> Ok "hidden"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    package_version : string;
    path : int;
    status : Status.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
