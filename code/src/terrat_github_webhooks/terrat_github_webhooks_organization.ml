type t = {
  avatar_url : string;
  description : string option; [@default None]
  events_url : string;
  hooks_url : string;
  html_url : string option; [@default None]
  id : int;
  issues_url : string;
  login : string;
  members_url : string;
  node_id : string;
  public_members_url : string;
  repos_url : string;
  url : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
