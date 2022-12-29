module Primary = struct
  module Prebuild_availability = struct
    let t_of_yojson = function
      | `String "none" -> Ok "none"
      | `String "ready" -> Ok "ready"
      | `String "in_progress" -> Ok "in_progress"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    cpus : int;
    display_name : string;
    memory_in_bytes : int;
    name : string;
    operating_system : string;
    prebuild_availability : Prebuild_availability.t option;
    storage_in_bytes : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
