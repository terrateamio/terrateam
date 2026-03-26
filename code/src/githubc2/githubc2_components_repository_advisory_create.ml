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
  credits : Credits.t option; [@default None]
  cve_id : string option; [@default None]
  cvss_vector_string : string option; [@default None]
  cwe_ids : Cwe_ids.t option; [@default None]
  description : string;
  severity : Severity.t option; [@default None]
  start_private_fork : bool; [@default false]
  summary : string;
  vulnerabilities : Vulnerabilities.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
