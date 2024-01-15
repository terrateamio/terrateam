module Lock_policy = struct
  let t_of_yojson = function
    | `String "apply" -> Ok "apply"
    | `String "merge" -> Ok "merge"
    | `String "none" -> Ok "none"
    | `String "strict" -> Ok "strict"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  apply : Terrat_repo_config_workflow_op_list.t option; [@default None]
  cdktf : bool; [@default false]
  engine : Terrat_repo_config_engine.t option; [@default None]
  lock_policy : Lock_policy.t; [@default "strict"]
  plan : Terrat_repo_config_workflow_op_list.t option; [@default None]
  tag_query : string;
  terraform_version : string option; [@default None]
  terragrunt : bool; [@default false]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
