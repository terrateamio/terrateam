module Primary = struct
  module Prebuild_availability = struct
    let t_of_yojson = function
      | `String "in_progress" -> Ok `In_progress
      | `String "none" -> Ok `None
      | `String "ready" -> Ok `Ready
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `In_progress -> `String "in_progress"
      | `None -> `String "none"
      | `Ready -> `String "ready"

    type t =
      ([ `In_progress
       | `None
       | `Ready
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    cpus : int;
    display_name : string;
    memory_in_bytes : int;
    name : string;
    operating_system : string;
    prebuild_availability : Prebuild_availability.t option; [@default None]
    storage_in_bytes : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
