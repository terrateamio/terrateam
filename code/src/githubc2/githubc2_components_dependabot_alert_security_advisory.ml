module Cvss = struct
  type t = {
    score : float;
    vector_string : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Cwes = struct
  module Items = struct
    type t = {
      cwe_id : string;
      name : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Identifiers = struct
  module Items = struct
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

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module References = struct
  module Items = struct
    type t = { url : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
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
  type t = Githubc2_components_dependabot_alert_security_vulnerability.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  cve_id : string option; [@default None]
  cvss : Cvss.t;
  cvss_severities : Githubc2_components_cvss_severities.t option; [@default None]
  cwes : Cwes.t;
  description : string;
  epss : Githubc2_components_security_advisory_epss.t option; [@default None]
  ghsa_id : string;
  identifiers : Identifiers.t;
  published_at : string;
  references : References.t;
  severity : Severity.t;
  summary : string;
  updated_at : string;
  vulnerabilities : Vulnerabilities.t;
  withdrawn_at : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
