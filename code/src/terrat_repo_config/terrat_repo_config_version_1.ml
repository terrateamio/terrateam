module Apply_requirements = struct
  module Checks = struct
    module Approved = struct
      type t = {
        count : int; [@default 1]
        enabled : bool; [@default false]
      }
      [@@deriving yojson { strict = true; meta = true }, make, show]
    end

    module Merge_conflicts = struct
      type t = { enabled : bool [@default true] }
      [@@deriving yojson { strict = true; meta = true }, make, show]
    end

    module Status_checks = struct
      module Ignore_matching = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        enabled : bool; [@default true]
        ignore_matching : Ignore_matching.t option; [@default None]
      }
      [@@deriving yojson { strict = true; meta = true }, make, show]
    end

    type t = {
      approved : Approved.t option; [@default None]
      merge_conflicts : Merge_conflicts.t option; [@default None]
      status_checks : Status_checks.t option; [@default None]
    }
    [@@deriving yojson { strict = true; meta = true }, make, show]
  end

  type t = {
    checks : Checks.t option; [@default None]
    create_pending_apply_check : bool; [@default true]
  }
  [@@deriving yojson { strict = true; meta = true }, make, show]
end

module Checkout_strategy = struct
  let t_of_yojson = function
    | `String "merge" -> Ok "merge"
    | `String "checkout" -> Ok "checkout"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

module Cost_estimation = struct
  module Provider = struct
    let t_of_yojson = function
      | `String "infracost" -> Ok "infracost"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    currency : string; [@default "USD"]
    enabled : bool; [@default true]
    provider : Provider.t; [@default "infracost"]
  }
  [@@deriving yojson { strict = true; meta = true }, make, show]
end

module Destination_branches = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show]
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
  cost_estimation : Cost_estimation.t option; [@default None]
  create_and_select_workspace : bool; [@default true]
  default_tf_version : string option; [@default None]
  destination_branches : Destination_branches.t option; [@default None]
  dirs : Dirs.t option; [@default None]
  enabled : bool; [@default true]
  hooks : Hooks.t option; [@default None]
  parallel_runs : int; [@default 3]
  version : Version.t; [@default "1"]
  when_modified : Terrat_repo_config_when_modified.t option; [@default None]
  workflows : Workflows.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show]
