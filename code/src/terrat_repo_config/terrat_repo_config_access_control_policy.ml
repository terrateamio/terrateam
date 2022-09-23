type t = {
  apply : Terrat_repo_config_access_control_match_list.t option; [@default None]
  apply_autoapprove : Terrat_repo_config_access_control_match_list.t option; [@default None]
  apply_force : Terrat_repo_config_access_control_match_list.t option; [@default None]
  apply_with_superapproval : Terrat_repo_config_access_control_match_list.t option; [@default None]
  plan : Terrat_repo_config_access_control_match_list.t option; [@default None]
  superapproval : Terrat_repo_config_access_control_match_list.t option; [@default None]
  tag_query : string;
}
[@@deriving yojson { strict = true; meta = true }, make, show]
