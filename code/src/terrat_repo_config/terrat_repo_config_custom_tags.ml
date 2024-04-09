type t = {
  branch : Terrat_repo_config_custom_tags_branch.t option; [@default None]
  dest_branch : Terrat_repo_config_custom_tags_branch.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
