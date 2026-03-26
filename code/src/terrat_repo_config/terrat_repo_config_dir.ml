module Lock_branch_target = struct
  let t_of_yojson = function
    | `String "all" -> Ok `All
    | `String "dest_branch" -> Ok `Dest_branch
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `All -> `String "all"
    | `Dest_branch -> `String "dest_branch"

  type t =
    ([ `All
     | `Dest_branch
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  create_and_select_workspace : bool; [@default true]
  create_if_missing : bool; [@default false]
  lock_branch_target : Lock_branch_target.t option; [@default None]
  stacks : Terrat_repo_config_workspaces.t option; [@default None]
  tags : Terrat_repo_config_tags.t option; [@default None]
  when_modified : Terrat_repo_config_when_modified_nullable.t option; [@default None]
  workspaces : Terrat_repo_config_workspaces.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
