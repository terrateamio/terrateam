let t_of_yojson = function
  | `String "fix_started" -> Ok "fix_started"
  | `String "inaccurate" -> Ok "inaccurate"
  | `String "no_bandwidth" -> Ok "no_bandwidth"
  | `String "not_used" -> Ok "not_used"
  | `String "tolerable_risk" -> Ok "tolerable_risk"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson]) option
[@@deriving yojson { strict = false; meta = true }, show]
