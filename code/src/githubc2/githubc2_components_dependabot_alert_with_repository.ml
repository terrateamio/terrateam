module Dependency_ = struct
  module Primary = struct
    module Relationship = struct
      let t_of_yojson = function
        | `String "direct" -> Ok `Direct
        | `String "transitive" -> Ok `Transitive
        | `String "unknown" -> Ok `Unknown
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      let t_to_yojson = function
        | `Direct -> `String "direct"
        | `Transitive -> `String "transitive"
        | `Unknown -> `String "unknown"

      type t =
        ([ `Direct
         | `Transitive
         | `Unknown
         ]
        [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Scope = struct
      let t_of_yojson = function
        | `String "development" -> Ok `Development
        | `String "runtime" -> Ok `Runtime
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      let t_to_yojson = function
        | `Development -> `String "development"
        | `Runtime -> `String "runtime"

      type t =
        ([ `Development
         | `Runtime
         ]
        [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = {
      manifest_path : string option; [@default None]
      package : Githubc2_components_dependabot_alert_package.t option; [@default None]
      relationship : Relationship.t option; [@default None]
      scope : Scope.t option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Dismissed_reason = struct
  let t_of_yojson = function
    | `String "fix_started" -> Ok `Fix_started
    | `String "inaccurate" -> Ok `Inaccurate
    | `String "no_bandwidth" -> Ok `No_bandwidth
    | `String "not_used" -> Ok `Not_used
    | `String "tolerable_risk" -> Ok `Tolerable_risk
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Fix_started -> `String "fix_started"
    | `Inaccurate -> `String "inaccurate"
    | `No_bandwidth -> `String "no_bandwidth"
    | `Not_used -> `String "not_used"
    | `Tolerable_risk -> `String "tolerable_risk"

  type t =
    ([ `Fix_started
     | `Inaccurate
     | `No_bandwidth
     | `Not_used
     | `Tolerable_risk
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module State = struct
  let t_of_yojson = function
    | `String "auto_dismissed" -> Ok `Auto_dismissed
    | `String "dismissed" -> Ok `Dismissed
    | `String "fixed" -> Ok `Fixed
    | `String "open" -> Ok `Open
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Auto_dismissed -> `String "auto_dismissed"
    | `Dismissed -> `String "dismissed"
    | `Fixed -> `String "fixed"
    | `Open -> `String "open"

  type t =
    ([ `Auto_dismissed
     | `Dismissed
     | `Fixed
     | `Open
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  auto_dismissed_at : string option; [@default None]
  created_at : string;
  dependency : Dependency_.t;
  dismissed_at : string option; [@default None]
  dismissed_by : Githubc2_components_nullable_simple_user.t option; [@default None]
  dismissed_comment : string option; [@default None]
  dismissed_reason : Dismissed_reason.t option; [@default None]
  fixed_at : string option; [@default None]
  html_url : string;
  number : int;
  repository : Githubc2_components_simple_repository.t;
  security_advisory : Githubc2_components_dependabot_alert_security_advisory.t;
  security_vulnerability : Githubc2_components_dependabot_alert_security_vulnerability.t;
  state : State.t;
  updated_at : string;
  url : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
