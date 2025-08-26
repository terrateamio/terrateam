module Stacks_ = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  rules : Terrat_repo_config_stack_rules.t option; [@default None]
  stacks : Stacks_.t;
  variables : Terrat_repo_config_stack_variables.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
