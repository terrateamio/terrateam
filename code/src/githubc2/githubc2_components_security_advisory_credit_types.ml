let t_of_yojson = function
  | `String "analyst" -> Ok "analyst"
  | `String "finder" -> Ok "finder"
  | `String "reporter" -> Ok "reporter"
  | `String "coordinator" -> Ok "coordinator"
  | `String "remediation_developer" -> Ok "remediation_developer"
  | `String "remediation_reviewer" -> Ok "remediation_reviewer"
  | `String "remediation_verifier" -> Ok "remediation_verifier"
  | `String "tool" -> Ok "tool"
  | `String "sponsor" -> Ok "sponsor"
  | `String "other" -> Ok "other"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
