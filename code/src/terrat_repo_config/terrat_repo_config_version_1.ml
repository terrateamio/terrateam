module Apply_requirements = struct
  module Checks = struct
    module Approved = struct
      type t = {
        count : int; [@default 1]
        enabled : bool; [@default false]
      }
      [@@deriving yojson { strict = true; meta = true }, make, show, eq]
    end

    module Merge_conflicts = struct
      type t = { enabled : bool [@default true] }
      [@@deriving yojson { strict = true; meta = true }, make, show, eq]
    end

    module Status_checks = struct
      module Ignore_matching = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        enabled : bool; [@default true]
        ignore_matching : Ignore_matching.t option; [@default None]
      }
      [@@deriving yojson { strict = true; meta = true }, make, show, eq]
    end

    type t = {
      approved : Approved.t option; [@default None]
      merge_conflicts : Merge_conflicts.t option; [@default None]
      status_checks : Status_checks.t option; [@default None]
    }
    [@@deriving yojson { strict = true; meta = true }, make, show, eq]
  end

  type t = {
    checks : Checks.t option; [@default None]
    create_pending_apply_check : bool; [@default true]
  }
  [@@deriving yojson { strict = true; meta = true }, make, show, eq]
end

module Checkout_strategy = struct
  let t_of_yojson = function
    | `String "merge" -> Ok "merge"
    | `String "checkout" -> Ok "checkout"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Cost_estimation = struct
  module Provider = struct
    let t_of_yojson = function
      | `String "infracost" -> Ok "infracost"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    currency : string; [@default "USD"]
    enabled : bool; [@default true]
    provider : Provider.t; [@default "infracost"]
  }
  [@@deriving yojson { strict = true; meta = true }, make, show, eq]
end

module Destination_branches = struct
  module Items = struct
    type t =
      | Destination_branch_name of Terrat_repo_config_destination_branch_name.t
      | Destination_branch_object of Terrat_repo_config_destination_branch_object.t
    [@@deriving show, eq]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
         [
           (fun v ->
             map
               (fun v -> Destination_branch_name v)
               (Terrat_repo_config_destination_branch_name.of_yojson v));
           (fun v ->
             map
               (fun v -> Destination_branch_object v)
               (Terrat_repo_config_destination_branch_object.of_yojson v));
         ])

    let to_yojson = function
      | Destination_branch_name v -> Terrat_repo_config_destination_branch_name.to_yojson v
      | Destination_branch_object v -> Terrat_repo_config_destination_branch_object.to_yojson v
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Dirs = struct
  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Terrat_repo_config_dir)
end

module Hooks = struct
  type t = {
    all : Terrat_repo_config_hook.t option; [@default None]
    apply : Terrat_repo_config_hook.t option; [@default None]
    plan : Terrat_repo_config_hook.t option; [@default None]
  }
  [@@deriving yojson { strict = true; meta = true }, make, show, eq]
end

module Indexer = struct
  type t = {
    build_tag : string option; [@default None]
    enabled : bool; [@default false]
  }
  [@@deriving yojson { strict = true; meta = true }, make, show, eq]
end

module Storage = struct
  module Plans = struct
    type t =
      | Storage_plan_terrateam of Terrat_repo_config_storage_plan_terrateam.t
      | Storage_plan_cmd of Terrat_repo_config_storage_plan_cmd.t
      | Storage_plan_s3 of Terrat_repo_config_storage_plan_s3.t
    [@@deriving show, eq]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
         [
           (fun v ->
             map
               (fun v -> Storage_plan_terrateam v)
               (Terrat_repo_config_storage_plan_terrateam.of_yojson v));
           (fun v ->
             map (fun v -> Storage_plan_cmd v) (Terrat_repo_config_storage_plan_cmd.of_yojson v));
           (fun v ->
             map (fun v -> Storage_plan_s3 v) (Terrat_repo_config_storage_plan_s3.of_yojson v));
         ])

    let to_yojson = function
      | Storage_plan_terrateam v -> Terrat_repo_config_storage_plan_terrateam.to_yojson v
      | Storage_plan_cmd v -> Terrat_repo_config_storage_plan_cmd.to_yojson v
      | Storage_plan_s3 v -> Terrat_repo_config_storage_plan_s3.to_yojson v
  end

  type t = { plans : Plans.t option [@default None] }
  [@@deriving yojson { strict = true; meta = true }, make, show, eq]
end

module Version = struct
  let t_of_yojson = function
    | `String "1" -> Ok "1"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Workflows = struct
  type t = Terrat_repo_config_workflow_entry.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  access_control : Terrat_repo_config_access_control.t option; [@default None]
  apply_requirements : Apply_requirements.t option; [@default None]
  automerge : Terrat_repo_config_automerge.t option; [@default None]
  checkout_strategy : Checkout_strategy.t; [@default "merge"]
  cost_estimation : Cost_estimation.t option; [@default None]
  create_and_select_workspace : bool; [@default true]
  default_tf_version : string option; [@default None]
  destination_branches : Destination_branches.t option; [@default None]
  dirs : Dirs.t option; [@default None]
  drift : Terrat_repo_config_drift.t option; [@default None]
  enabled : bool; [@default true]
  engine : Terrat_repo_config_engine.t option; [@default None]
  hooks : Hooks.t option; [@default None]
  indexer : Indexer.t option; [@default None]
  integrations : Terrat_repo_config_integrations.t option; [@default None]
  parallel_runs : int; [@default 3]
  storage : Storage.t option; [@default None]
  tags : Terrat_repo_config_custom_tags.t option; [@default None]
  version : Version.t; [@default "1"]
  when_modified : Terrat_repo_config_when_modified.t option; [@default None]
  workflows : Workflows.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
