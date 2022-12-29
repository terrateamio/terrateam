type t = {
  author : Terrat_github_webhooks_committer.t;
  committer : Terrat_github_webhooks_committer.t;
  id : string;
  message : string;
  timestamp : string;
  tree_id : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
