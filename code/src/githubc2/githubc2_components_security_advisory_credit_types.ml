let t_of_yojson = function
  | `String "analyst" -> Ok `Analyst
  | `String "coordinator" -> Ok `Coordinator
  | `String "finder" -> Ok `Finder
  | `String "other" -> Ok `Other
  | `String "remediation_developer" -> Ok `Remediation_developer
  | `String "remediation_reviewer" -> Ok `Remediation_reviewer
  | `String "remediation_verifier" -> Ok `Remediation_verifier
  | `String "reporter" -> Ok `Reporter
  | `String "sponsor" -> Ok `Sponsor
  | `String "tool" -> Ok `Tool
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Analyst -> `String "analyst"
  | `Coordinator -> `String "coordinator"
  | `Finder -> `String "finder"
  | `Other -> `String "other"
  | `Remediation_developer -> `String "remediation_developer"
  | `Remediation_reviewer -> `String "remediation_reviewer"
  | `Remediation_verifier -> `String "remediation_verifier"
  | `Reporter -> `String "reporter"
  | `Sponsor -> `String "sponsor"
  | `Tool -> `String "tool"

type t =
  ([ `Analyst
   | `Coordinator
   | `Finder
   | `Other
   | `Remediation_developer
   | `Remediation_reviewer
   | `Remediation_verifier
   | `Reporter
   | `Sponsor
   | `Tool
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
