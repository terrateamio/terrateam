module Cvss = struct
  type t = {
    score : float;
    vector_string : string option;
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
    | `String "low" -> Ok "low"
    | `String "medium" -> Ok "medium"
    | `String "high" -> Ok "high"
    | `String "critical" -> Ok "critical"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Vulnerabilities = struct
  type t = Githubc2_components_dependabot_alert_security_vulnerability.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  cve_id : string option;
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
  withdrawn_at : string option;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
