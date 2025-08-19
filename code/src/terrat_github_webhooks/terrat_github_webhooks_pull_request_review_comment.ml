module Links_ = struct
  type t = {
    html : Terrat_github_webhooks_link.t;
    pull_request : Terrat_github_webhooks_link.t;
    self : Terrat_github_webhooks_link.t;
  }
  [@@deriving yojson { strict = false; meta = true }, make, show, eq]
end

module Side = struct
  let t_of_yojson = function
    | `String "LEFT" -> Ok "LEFT"
    | `String "RIGHT" -> Ok "RIGHT"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  links_ : Links_.t; [@key "_links"]
  author_association : string;
  body : string;
  commit_id : string;
  created_at : string;
  diff_hunk : string;
  html_url : string;
  id : int;
  in_reply_to_id : int option; [@default None]
  line : int option; [@default None]
  node_id : string;
  original_commit_id : string;
  original_line : int;
  original_position : int;
  original_start_line : int option; [@default None]
  path : string;
  position : int option; [@default None]
  pull_request_review_id : int;
  pull_request_url : string;
  reactions : Terrat_github_webhooks_reactions.t;
  side : Side.t;
  start_line : int option; [@default None]
  start_side : string option; [@default Some "RIGHT"]
  updated_at : string;
  url : string;
  user : Terrat_github_webhooks_user.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
