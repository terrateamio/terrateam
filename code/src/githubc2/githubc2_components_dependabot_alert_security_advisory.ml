module Cvss = struct
  type t = {
    score : float;
    vector_string : string option;
  }
  [@@deriving yojson { strict = true; meta = true }, show]
end

module Cwes = struct
  module Items = struct
    type t = {
      cwe_id : string;
      name : string;
    }
    [@@deriving yojson { strict = true; meta = true }, show]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
end

module Identifiers = struct
  module Items = struct
    module Type = struct
      let t_of_yojson = function
        | `String "GHSA" -> Ok "GHSA"
        | `String "CVE" -> Ok "CVE"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      type_ : Type.t; [@key "type"]
      value : string;
    }
    [@@deriving yojson { strict = true; meta = true }, show]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
end

module References = struct
  module Items = struct
    type t = { url : string } [@@deriving yojson { strict = true; meta = true }, show]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
end

module Severity = struct
  let t_of_yojson = function
    | `String "low" -> Ok "low"
    | `String "medium" -> Ok "medium"
    | `String "high" -> Ok "high"
    | `String "critical" -> Ok "critical"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

module Vulnerabilities = struct
  module Items = struct
    module First_patched_version = struct
      type t = { identifier : string } [@@deriving yojson { strict = true; meta = true }, show]
    end

    module Package_ = struct
      type t = {
        ecosystem : string;
        name : string;
      }
      [@@deriving yojson { strict = true; meta = true }, show]
    end

    type t = {
      first_patched_version : First_patched_version.t option;
      package : Package_.t;
      severity : string;
      vulnerable_version_range : string;
    }
    [@@deriving yojson { strict = true; meta = true }, show]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
end

type t = {
  cve_id : string option; [@default None]
  cvss : Cvss.t;
  cwes : Cwes.t;
  description : string;
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
[@@deriving yojson { strict = true; meta = true }, show]