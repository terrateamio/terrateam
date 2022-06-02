let t_of_yojson = function
  | `String "COLLABORATOR" -> Ok "COLLABORATOR"
  | `String "CONTRIBUTOR" -> Ok "CONTRIBUTOR"
  | `String "FIRST_TIMER" -> Ok "FIRST_TIMER"
  | `String "FIRST_TIME_CONTRIBUTOR" -> Ok "FIRST_TIME_CONTRIBUTOR"
  | `String "MANNEQUIN" -> Ok "MANNEQUIN"
  | `String "MEMBER" -> Ok "MEMBER"
  | `String "NONE" -> Ok "NONE"
  | `String "OWNER" -> Ok "OWNER"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson]) [@@deriving yojson { strict = false; meta = true }, show]
