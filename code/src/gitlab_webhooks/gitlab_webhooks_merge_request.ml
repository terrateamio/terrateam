type t = {
  created_at : string;
  id : int;
  iid : int option; [@default None]
  source : Gitlab_webhooks_project.t;
  source_branch : string;
  target : Gitlab_webhooks_project.t;
  target_branch : string;
  title : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
