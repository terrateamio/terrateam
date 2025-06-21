module Primary = struct
  module Auto_stop_setting = struct
    let t_of_yojson = function
      | `String "always" -> Ok "always"
      | `String "with_action" -> Ok "with_action"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Tier = struct
    let t_of_yojson = function
      | `String "production" -> Ok "production"
      | `String "staging" -> Ok "staging"
      | `String "testing" -> Ok "testing"
      | `String "development" -> Ok "development"
      | `String "other" -> Ok "other"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    auto_stop_setting : Auto_stop_setting.t option; [@default None]
    cluster_agent_id : int option; [@default None]
    description : string option; [@default None]
    external_url : string option; [@default None]
    flux_resource_path : string option; [@default None]
    kubernetes_namespace : string option; [@default None]
    tier : Tier.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
