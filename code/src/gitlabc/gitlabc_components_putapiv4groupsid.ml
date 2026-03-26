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
    | `String "default_off" -> Ok `Default_off
    | `String "default_on" -> Ok `Default_on
    | `String "never_on" -> Ok `Never_on
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Default_off -> `String "default_off"
    | `Default_on -> `String "default_on"
    | `Never_on -> `String "never_on"

  type t =
    ([ `Default_off
     | `Default_on
     | `Never_on
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Enabled_git_access_protocol = struct
  let t_of_yojson = function
    | `String "all" -> Ok `All
    | `String "http" -> Ok `Http
    | `String "ssh" -> Ok `Ssh
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `All -> `String "all"
    | `Http -> `String "http"
    | `Ssh -> `String "ssh"

  type t =
    ([ `All
     | `Http
     | `Ssh
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Project_creation_level = struct
  let t_of_yojson = function
    | `String "administrator" -> Ok `Administrator
    | `String "developer" -> Ok `Developer
    | `String "maintainer" -> Ok `Maintainer
    | `String "noone" -> Ok `Noone
    | `String "owner" -> Ok `Owner
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Administrator -> `String "administrator"
    | `Developer -> `String "developer"
    | `Maintainer -> `String "maintainer"
    | `Noone -> `String "noone"
    | `Owner -> `String "owner"

  type t =
    ([ `Administrator
     | `Developer
     | `Maintainer
     | `Noone
     | `Owner
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Shared_runners_setting = struct
  let t_of_yojson = function
    | `String "disabled_and_overridable" -> Ok `Disabled_and_overridable
    | `String "disabled_and_unoverridable" -> Ok `Disabled_and_unoverridable
    | `String "enabled" -> Ok `Enabled
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Disabled_and_overridable -> `String "disabled_and_overridable"
    | `Disabled_and_unoverridable -> `String "disabled_and_unoverridable"
    | `Enabled -> `String "enabled"

  type t =
    ([ `Disabled_and_overridable
     | `Disabled_and_unoverridable
     | `Enabled
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Subgroup_creation_level = struct
  let t_of_yojson = function
    | `String "maintainer" -> Ok `Maintainer
    | `String "owner" -> Ok `Owner
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Maintainer -> `String "maintainer"
    | `Owner -> `String "owner"

  type t =
    ([ `Maintainer
     | `Owner
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
    | `String "internal" -> Ok `Internal
    | `String "private" -> Ok `Private
    | `String "public" -> Ok `Public
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Internal -> `String "internal"
    | `Private -> `String "private"
    | `Public -> `String "public"

  type t =
    ([ `Internal
     | `Private
     | `Public
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Wiki_access_level = struct
  let t_of_yojson = function
    | `String "disabled" -> Ok `Disabled
    | `String "enabled" -> Ok `Enabled
    | `String "private" -> Ok `Private
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Disabled -> `String "disabled"
    | `Enabled -> `String "enabled"
    | `Private -> `String "private"

  type t =
    ([ `Disabled
     | `Enabled
     | `Private
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  allowed_email_domains_list : string option; [@default None]
  auto_ban_user_on_excessive_projects_download : bool option; [@default None]
  auto_devops_enabled : bool option; [@default None]
  avatar : string option; [@default None]
  default_branch : string option; [@default None]
  default_branch_protection : int option; [@default None]
  default_branch_protection_defaults : Default_branch_protection_defaults.t option; [@default None]
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
