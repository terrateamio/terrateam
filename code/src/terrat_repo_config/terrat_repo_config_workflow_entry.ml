type t = {
  apply : Terrat_repo_config_workflow_op_list.t option; [@default None]
  plan : Terrat_repo_config_workflow_op_list.t option; [@default None]
  tag_query : string;
}
[@@deriving yojson { strict = true; meta = true }, make, show]