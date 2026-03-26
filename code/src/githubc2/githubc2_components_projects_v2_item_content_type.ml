let t_of_yojson = function
  | `String "DraftIssue" -> Ok `DraftIssue
  | `String "Issue" -> Ok `Issue
  | `String "PullRequest" -> Ok `PullRequest
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `DraftIssue -> `String "DraftIssue"
  | `Issue -> `String "Issue"
  | `PullRequest -> `String "PullRequest"

type t =
  ([ `DraftIssue
   | `Issue
   | `PullRequest
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
