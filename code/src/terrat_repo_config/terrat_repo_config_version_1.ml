module Apply_requirements = struct
  module Items = struct
    let t_of_yojson = function
      | `String "mergeable" -> Ok "mergeable"
      | `String "approved" -> Ok "approved"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
end

module Checkout_strategy = struct
  let t_of_yojson = function
    | `String "merge" -> Ok "merge"
    | `String "checkout" -> Ok "checkout"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

module Dirs = struct
  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Terrat_repo_config_dir)
end

module Hooks = struct
  type t = {
    apply : Terrat_repo_config_hook.t option; [@default None]
    plan : Terrat_repo_config_hook.t option; [@default None]
  }
  [@@deriving yojson { strict = true; meta = true }, make, show]
end

module Version = struct
  let t_of_yojson = function
    | `String "1" -> Ok "1"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

module Workflows = struct
  type t = Terrat_repo_config_workflow_entry.t list
  [@@deriving yojson { strict = false; meta = true }, show]
end

type t = {
  apply_requirements : Apply_requirements.t option; [@default None]
  automerge : Terrat_repo_config_automerge.t option; [@default None]
  checkout_strategy : Checkout_strategy.t; [@default "merge"]
  default_tf_version : Terrat_repo_config_terraform_version.t option; [@default None]
  dirs : Dirs.t option; [@default None]
  enabled : bool; [@default true]
  hooks : Hooks.t option; [@default None]
  parallel_runs : int; [@default 3]
  version : Version.t; [@default "1"]
  when_modified : Terrat_repo_config_when_modified.t option; [@default None]
  workflows : Workflows.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show]
