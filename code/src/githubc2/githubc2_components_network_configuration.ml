module Primary = struct
  module Compute_service = struct
    let t_of_yojson = function
      | `String "actions" -> Ok `Actions
      | `String "codespaces" -> Ok `Codespaces
      | `String "none" -> Ok `None
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Actions -> `String "actions"
      | `Codespaces -> `String "codespaces"
      | `None -> `String "none"

    type t =
      ([ `Actions
       | `Codespaces
       | `None
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
