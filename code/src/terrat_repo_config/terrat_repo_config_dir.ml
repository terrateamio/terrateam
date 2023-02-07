type t = {
  create_and_select_workspace : bool; [@default true]
  stacks : Terrat_repo_config_workspaces.t option; [@default None]
  tags : Terrat_repo_config_tags.t option; [@default None]
  when_modified : Terrat_repo_config_when_modified_nullable.t option; [@default None]
  workspaces : Terrat_repo_config_workspaces.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
