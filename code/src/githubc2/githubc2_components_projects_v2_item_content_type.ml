let t_of_yojson = function
  | `String "Issue" -> Ok "Issue"
  | `String "PullRequest" -> Ok "PullRequest"
  | `String "DraftIssue" -> Ok "DraftIssue"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
