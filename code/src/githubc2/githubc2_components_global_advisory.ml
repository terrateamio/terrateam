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
      score : float option; [@default None]
      vector_string : string option; [@default None]
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
          | `String "CVE" -> Ok `CVE
          | `String "GHSA" -> Ok `GHSA
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `CVE -> `String "CVE"
          | `GHSA -> `String "GHSA"

        type t =
          ([ `CVE
           | `GHSA
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
    | `String "critical" -> Ok `Critical
    | `String "high" -> Ok `High
    | `String "low" -> Ok `Low
    | `String "medium" -> Ok `Medium
    | `String "unknown" -> Ok `Unknown
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Critical -> `String "critical"
    | `High -> `String "high"
    | `Low -> `String "low"
    | `Medium -> `String "medium"
    | `Unknown -> `String "unknown"

  type t =
    ([ `Critical
     | `High
     | `Low
     | `Medium
     | `Unknown
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Type = struct
  let t_of_yojson = function
    | `String "malware" -> Ok `Malware
    | `String "reviewed" -> Ok `Reviewed
    | `String "unreviewed" -> Ok `Unreviewed
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Malware -> `String "malware"
    | `Reviewed -> `String "reviewed"
    | `Unreviewed -> `String "unreviewed"

  type t =
    ([ `Malware
     | `Reviewed
     | `Unreviewed
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Vulnerabilities = struct
  type t = Githubc2_components_vulnerability.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  credits : Credits.t option; [@default None]
  cve_id : string option; [@default None]
  cvss : Cvss.t option; [@default None]
  cvss_severities : Githubc2_components_cvss_severities.t option; [@default None]
  cwes : Cwes.t option; [@default None]
  description : string option; [@default None]
  epss : Githubc2_components_security_advisory_epss.t option; [@default None]
  ghsa_id : string;
  github_reviewed_at : string option; [@default None]
  html_url : string;
  identifiers : Identifiers.t option; [@default None]
  nvd_published_at : string option; [@default None]
  published_at : string;
  references : References.t option; [@default None]
  repository_advisory_url : string option; [@default None]
  severity : Severity.t;
  source_code_location : string option; [@default None]
  summary : string;
  type_ : Type.t; [@key "type"]
  updated_at : string;
  url : string;
  vulnerabilities : Vulnerabilities.t option; [@default None]
  withdrawn_at : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
