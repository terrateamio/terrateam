module Primary = struct
  module Compute_service = struct
    let t_of_yojson = function
      | `String "none" -> Ok "none"
      | `String "actions" -> Ok "actions"
      | `String "codespaces" -> Ok "codespaces"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Network_settings_ids = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    compute_service : Compute_service.t option; [@default None]
    created_on : string option; [@default None]
    id : string;
    name : string;
    network_settings_ids : Network_settings_ids.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
