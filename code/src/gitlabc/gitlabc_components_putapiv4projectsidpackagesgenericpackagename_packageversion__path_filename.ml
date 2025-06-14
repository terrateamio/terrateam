module Primary = struct
  module Select = struct
    let t_of_yojson = function
      | `String "package_file" -> Ok "package_file"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Status = struct
    let t_of_yojson = function
      | `String "default" -> Ok "default"
      | `String "hidden" -> Ok "hidden"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    file : string;
    package_version : string;
    path : string option; [@default None]
    select : Select.t option; [@default None]
    status : Status.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
