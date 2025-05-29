module Primary = struct
  module Default_branch_protection_defaults = struct
    module Primary = struct
      module Allowed_to_merge = struct
        module Items = struct
          module Primary = struct
            type t = { access_level : int }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Allowed_to_push = struct
        module Items = struct
          module Primary = struct
            type t = { access_level : int }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        allow_force_push : bool option; [@default None]
        allowed_to_merge : Allowed_to_merge.t option; [@default None]
        allowed_to_push : Allowed_to_push.t option; [@default None]
        code_owner_approval_required : bool option; [@default None]
        developer_can_initial_push : bool option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Duo_availability = struct
    let t_of_yojson = function
      | `String "default_on" -> Ok "default_on"
      | `String "default_off" -> Ok "default_off"
      | `String "never_on" -> Ok "never_on"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Enabled_git_access_protocol = struct
    let t_of_yojson = function
      | `String "ssh" -> Ok "ssh"
      | `String "http" -> Ok "http"
      | `String "all" -> Ok "all"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Project_creation_level = struct
    let t_of_yojson = function
      | `String "noone" -> Ok "noone"
      | `String "owner" -> Ok "owner"
      | `String "maintainer" -> Ok "maintainer"
      | `String "developer" -> Ok "developer"
      | `String "administrator" -> Ok "administrator"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Shared_runners_setting = struct
    let t_of_yojson = function
      | `String "disabled_and_unoverridable" -> Ok "disabled_and_unoverridable"
      | `String "disabled_and_overridable" -> Ok "disabled_and_overridable"
      | `String "enabled" -> Ok "enabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Subgroup_creation_level = struct
    let t_of_yojson = function
      | `String "owner" -> Ok "owner"
      | `String "maintainer" -> Ok "maintainer"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Unique_project_download_limit_alertlist = struct
    type t = int list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Unique_project_download_limit_allowlist = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Visibility = struct
    let t_of_yojson = function
      | `String "private" -> Ok "private"
      | `String "internal" -> Ok "internal"
      | `String "public" -> Ok "public"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Wiki_access_level = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok "disabled"
      | `String "private" -> Ok "private"
      | `String "enabled" -> Ok "enabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    allowed_email_domains_list : string option; [@default None]
    auto_ban_user_on_excessive_projects_download : bool option; [@default None]
    auto_devops_enabled : bool option; [@default None]
    avatar : string option; [@default None]
    default_branch : string option; [@default None]
    default_branch_protection : int option; [@default None]
    default_branch_protection_defaults : Default_branch_protection_defaults.t option;
        [@default None]
    description : string option; [@default None]
    duo_availability : Duo_availability.t option; [@default None]
    duo_features_enabled : bool option; [@default None]
    emails_disabled : bool option; [@default None]
    emails_enabled : bool option; [@default None]
    enabled_git_access_protocol : Enabled_git_access_protocol.t option; [@default None]
    experiment_features_enabled : bool option; [@default None]
    extra_shared_runners_minutes_limit : int option; [@default None]
    file_template_project_id : int option; [@default None]
    ip_restriction_ranges : string option; [@default None]
    ldap_access : int option; [@default None]
    ldap_cn : string option; [@default None]
    lfs_enabled : bool option; [@default None]
    lock_duo_features_enabled : bool option; [@default None]
    lock_math_rendering_limits_enabled : bool option; [@default None]
    math_rendering_limits_enabled : bool option; [@default None]
    max_artifacts_size : int option; [@default None]
    membership_lock : bool option; [@default None]
    mentions_disabled : bool option; [@default None]
    name : string option; [@default None]
    path : string option; [@default None]
    prevent_forking_outside_group : bool option; [@default None]
    prevent_sharing_groups_outside_hierarchy : bool option; [@default None]
    project_creation_level : Project_creation_level.t option; [@default None]
    request_access_enabled : bool option; [@default None]
    require_two_factor_authentication : bool option; [@default None]
    service_access_tokens_expiration_enforced : bool option; [@default None]
    share_with_group_lock : bool option; [@default None]
    shared_runners_minutes_limit : int option; [@default None]
    shared_runners_setting : Shared_runners_setting.t option; [@default None]
    show_diff_preview_in_email : bool option; [@default None]
    subgroup_creation_level : Subgroup_creation_level.t option; [@default None]
    two_factor_grace_period : int option; [@default None]
    unique_project_download_limit : int option; [@default None]
    unique_project_download_limit_alertlist : Unique_project_download_limit_alertlist.t option;
        [@default None]
    unique_project_download_limit_allowlist : Unique_project_download_limit_allowlist.t option;
        [@default None]
    unique_project_download_limit_interval_in_seconds : int option; [@default None]
    visibility : Visibility.t option; [@default None]
    wiki_access_level : Wiki_access_level.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
