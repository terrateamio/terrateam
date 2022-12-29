type t = {
  post : Terrat_repo_config_hook_list.t option; [@default None]
  pre : Terrat_repo_config_hook_list.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
