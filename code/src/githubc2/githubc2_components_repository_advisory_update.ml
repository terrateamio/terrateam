module Collaborating_teams = struct
  type t = string list option [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Collaborating_users = struct
  type t = string list option [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Credits = struct
  module Items = struct
    type t = {
      login : string;
      type_ : Githubc2_components_security_advisory_credit_types.t; [@key "type"]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Cwe_ids = struct
  type t = string list option [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Severity = struct
  let t_of_yojson = function
    | `String "critical" -> Ok `Critical
    | `String "high" -> Ok `High
    | `String "low" -> Ok `Low
    | `String "medium" -> Ok `Medium
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Critical -> `String "critical"
    | `High -> `String "high"
    | `Low -> `String "low"
    | `Medium -> `String "medium"

  type t =
    ([ `Critical
     | `High
     | `Low
     | `Medium
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module State = struct
  let t_of_yojson = function
    | `String "closed" -> Ok `Closed
    | `String "draft" -> Ok `Draft
    | `String "published" -> Ok `Published
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Closed -> `String "closed"
    | `Draft -> `String "draft"
    | `Published -> `String "published"

  type t =
    ([ `Closed
     | `Draft
     | `Published
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Vulnerabilities = struct
  module Items = struct
    module Package_ = struct
      module Primary = struct
        type t = {
          ecosystem : Githubc2_components_security_advisory_ecosystems.t;
          name : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Vulnerable_functions = struct
      type t = string list option [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = {
      package : Package_.t;
      patched_versions : string option; [@default None]
      vulnerable_functions : Vulnerable_functions.t option; [@default None]
      vulnerable_version_range : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  collaborating_teams : Collaborating_teams.t option; [@default None]
  collaborating_users : Collaborating_users.t option; [@default None]
  credits : Credits.t option; [@default None]
  cve_id : string option; [@default None]
  cvss_vector_string : string option; [@default None]
  cwe_ids : Cwe_ids.t option; [@default None]
  description : string option; [@default None]
  severity : Severity.t option; [@default None]
  state : State.t option; [@default None]
  summary : string option; [@default None]
  vulnerabilities : Vulnerabilities.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
