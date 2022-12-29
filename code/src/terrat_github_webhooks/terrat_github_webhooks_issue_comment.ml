type t = {
  author_association : string;
  body : string;
  created_at : string;
  html_url : string;
  id : int;
  issue_url : string;
  node_id : string;
  performed_via_github_app : Terrat_github_webhooks_app.t option; [@default None]
  reactions : Terrat_github_webhooks_reactions.t;
  updated_at : string;
  url : string;
  user : Terrat_github_webhooks_user.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
