type t = {
  rules : Terrat_repo_config_stack_rules.t option; [@default None]
  tag_query : string;
  variables : Terrat_repo_config_stack_variables.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
