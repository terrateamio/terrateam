module Credits = struct
  module Items = struct
    type t = {
      login : string;
      type_ : Githubc2_components_security_advisory_credit_types.t; [@key "type"]
    }
    [@@deriving yojson { strict = true; meta = true }, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Cwe_ids = struct
  type t = string list option [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Severity = struct
  let t_of_yojson = function
    | `String "critical" -> Ok "critical"
    | `String "high" -> Ok "high"
    | `String "medium" -> Ok "medium"
    | `String "low" -> Ok "low"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
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
    [@@deriving yojson { strict = true; meta = true }, show, eq]
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
  summary : string;
  vulnerabilities : Vulnerabilities.t;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]
