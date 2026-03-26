let t_of_yojson = function
  | `String "COLLABORATOR" -> Ok `COLLABORATOR
  | `String "CONTRIBUTOR" -> Ok `CONTRIBUTOR
  | `String "FIRST_TIMER" -> Ok `FIRST_TIMER
  | `String "FIRST_TIME_CONTRIBUTOR" -> Ok `FIRST_TIME_CONTRIBUTOR
  | `String "MANNEQUIN" -> Ok `MANNEQUIN
  | `String "MEMBER" -> Ok `MEMBER
  | `String "NONE" -> Ok `NONE
  | `String "OWNER" -> Ok `OWNER
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `COLLABORATOR -> `String "COLLABORATOR"
  | `CONTRIBUTOR -> `String "CONTRIBUTOR"
  | `FIRST_TIMER -> `String "FIRST_TIMER"
  | `FIRST_TIME_CONTRIBUTOR -> `String "FIRST_TIME_CONTRIBUTOR"
  | `MANNEQUIN -> `String "MANNEQUIN"
  | `MEMBER -> `String "MEMBER"
  | `NONE -> `String "NONE"
  | `OWNER -> `String "OWNER"

type t =
  ([ `COLLABORATOR
   | `CONTRIBUTOR
   | `FIRST_TIMER
   | `FIRST_TIME_CONTRIBUTOR
   | `MANNEQUIN
   | `MEMBER
   | `NONE
   | `OWNER
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
