type t = {
  commit_message : string option; [@default None]
  commit_title : string option; [@default None]
  enabled_by : Terrat_github_webhooks_user.t option; [@default None]
  merge_method : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
