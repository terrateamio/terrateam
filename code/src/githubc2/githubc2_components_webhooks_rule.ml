module Primary = struct
  module Allow_deletions_enforcement_level = struct
    let t_of_yojson = function
      | `String "off" -> Ok "off"
      | `String "non_admins" -> Ok "non_admins"
      | `String "everyone" -> Ok "everyone"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Allow_force_pushes_enforcement_level = struct
    let t_of_yojson = function
      | `String "off" -> Ok "off"
      | `String "non_admins" -> Ok "non_admins"
      | `String "everyone" -> Ok "everyone"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Authorized_actor_names = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Linear_history_requirement_enforcement_level = struct
    let t_of_yojson = function
      | `String "off" -> Ok "off"
      | `String "non_admins" -> Ok "non_admins"
      | `String "everyone" -> Ok "everyone"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Lock_branch_enforcement_level = struct
    let t_of_yojson = function
      | `String "off" -> Ok "off"
      | `String "non_admins" -> Ok "non_admins"
      | `String "everyone" -> Ok "everyone"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Merge_queue_enforcement_level = struct
    let t_of_yojson = function
      | `String "off" -> Ok "off"
      | `String "non_admins" -> Ok "non_admins"
      | `String "everyone" -> Ok "everyone"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Pull_request_reviews_enforcement_level = struct
    let t_of_yojson = function
      | `String "off" -> Ok "off"
      | `String "non_admins" -> Ok "non_admins"
      | `String "everyone" -> Ok "everyone"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Required_conversation_resolution_level = struct
    let t_of_yojson = function
      | `String "off" -> Ok "off"
      | `String "non_admins" -> Ok "non_admins"
      | `String "everyone" -> Ok "everyone"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Required_deployments_enforcement_level = struct
    let t_of_yojson = function
      | `String "off" -> Ok "off"
      | `String "non_admins" -> Ok "non_admins"
      | `String "everyone" -> Ok "everyone"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Required_status_checks = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Required_status_checks_enforcement_level = struct
    let t_of_yojson = function
      | `String "off" -> Ok "off"
      | `String "non_admins" -> Ok "non_admins"
      | `String "everyone" -> Ok "everyone"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Signature_requirement_enforcement_level = struct
    let t_of_yojson = function
      | `String "off" -> Ok "off"
      | `String "non_admins" -> Ok "non_admins"
      | `String "everyone" -> Ok "everyone"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    admin_enforced : bool;
    allow_deletions_enforcement_level : Allow_deletions_enforcement_level.t;
    allow_force_pushes_enforcement_level : Allow_force_pushes_enforcement_level.t;
    authorized_actor_names : Authorized_actor_names.t;
    authorized_actors_only : bool;
    authorized_dismissal_actors_only : bool;
    create_protected : bool option; [@default None]
    created_at : string;
    dismiss_stale_reviews_on_push : bool;
    id : int;
    ignore_approvals_from_contributors : bool;
    linear_history_requirement_enforcement_level : Linear_history_requirement_enforcement_level.t;
    lock_allows_fork_sync : bool option; [@default None]
    lock_branch_enforcement_level : Lock_branch_enforcement_level.t;
    merge_queue_enforcement_level : Merge_queue_enforcement_level.t;
    name : string;
    pull_request_reviews_enforcement_level : Pull_request_reviews_enforcement_level.t;
    repository_id : int;
    require_code_owner_review : bool;
    require_last_push_approval : bool option; [@default None]
    required_approving_review_count : int;
    required_conversation_resolution_level : Required_conversation_resolution_level.t;
    required_deployments_enforcement_level : Required_deployments_enforcement_level.t;
    required_status_checks : Required_status_checks.t;
    required_status_checks_enforcement_level : Required_status_checks_enforcement_level.t;
    signature_requirement_enforcement_level : Signature_requirement_enforcement_level.t;
    strict_required_status_checks_policy : bool;
    updated_at : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
