module Dependency_ = struct
  module Primary = struct
    module Relationship = struct
      let t_of_yojson = function
        | `String "unknown" -> Ok "unknown"
        | `String "direct" -> Ok "direct"
        | `String "transitive" -> Ok "transitive"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Scope = struct
      let t_of_yojson = function
        | `String "development" -> Ok "development"
        | `String "runtime" -> Ok "runtime"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
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
    | `String "fix_started" -> Ok "fix_started"
    | `String "inaccurate" -> Ok "inaccurate"
    | `String "no_bandwidth" -> Ok "no_bandwidth"
    | `String "not_used" -> Ok "not_used"
    | `String "tolerable_risk" -> Ok "tolerable_risk"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module State = struct
  let t_of_yojson = function
    | `String "auto_dismissed" -> Ok "auto_dismissed"
    | `String "dismissed" -> Ok "dismissed"
    | `String "fixed" -> Ok "fixed"
    | `String "open" -> Ok "open"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
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
  security_advisory : Githubc2_components_dependabot_alert_security_advisory.t;
  security_vulnerability : Githubc2_components_dependabot_alert_security_vulnerability.t;
  state : State.t;
  updated_at : string;
  url : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
