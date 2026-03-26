module Auto_stop_setting = struct
  let t_of_yojson = function
    | `String "always" -> Ok `Always
    | `String "with_action" -> Ok `With_action
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Always -> `String "always"
    | `With_action -> `String "with_action"

  type t =
    ([ `Always
     | `With_action
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Tier = struct
  let t_of_yojson = function
    | `String "development" -> Ok `Development
    | `String "other" -> Ok `Other
    | `String "production" -> Ok `Production
    | `String "staging" -> Ok `Staging
    | `String "testing" -> Ok `Testing
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Development -> `String "development"
    | `Other -> `String "other"
    | `Production -> `String "production"
    | `Staging -> `String "staging"
    | `Testing -> `String "testing"

  type t =
    ([ `Development
     | `Other
     | `Production
     | `Staging
     | `Testing
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
