module Credits = struct
  module Items = struct
    module Primary = struct
      type t = {
        type_ : Githubc2_components_security_advisory_credit_types.t; [@key "type"]
        user : Githubc2_components_simple_user.t;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Cvss = struct
  module Primary = struct
    type t = {
      score : float option;
      vector_string : string option;
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Cwes = struct
  module Items = struct
    module Primary = struct
      type t = {
        cwe_id : string;
        name : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Identifiers = struct
  module Items = struct
    module Primary = struct
      module Type = struct
        let t_of_yojson = function
          | `String "CVE" -> Ok "CVE"
          | `String "GHSA" -> Ok "GHSA"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        type_ : Type.t; [@key "type"]
        value : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module References = struct
  type t = string list option [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Severity = struct
  let t_of_yojson = function
    | `String "critical" -> Ok "critical"
    | `String "high" -> Ok "high"
    | `String "medium" -> Ok "medium"
    | `String "low" -> Ok "low"
    | `String "unknown" -> Ok "unknown"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Type = struct
  let t_of_yojson = function
    | `String "reviewed" -> Ok "reviewed"
    | `String "unreviewed" -> Ok "unreviewed"
    | `String "malware" -> Ok "malware"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Vulnerabilities = struct
  type t = Githubc2_components_vulnerability.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  credits : Credits.t option;
  cve_id : string option;
  cvss : Cvss.t option;
  cvss_severities : Githubc2_components_cvss_severities.t option; [@default None]
  cwes : Cwes.t option;
  description : string option;
  epss : Githubc2_components_security_advisory_epss.t option; [@default None]
  ghsa_id : string;
  github_reviewed_at : string option;
  html_url : string;
  identifiers : Identifiers.t option;
  nvd_published_at : string option;
  published_at : string;
  references : References.t option;
  repository_advisory_url : string option;
  severity : Severity.t;
  source_code_location : string option;
  summary : string;
  type_ : Type.t; [@key "type"]
  updated_at : string;
  url : string;
  vulnerabilities : Vulnerabilities.t option;
  withdrawn_at : string option;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
