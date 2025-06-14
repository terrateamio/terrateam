module Default_branch_protection = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Default_branch_protection_defaults = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Mentions_disabled = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Parent_id = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Root_storage_statistics = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Saml_group_links = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Statistics = struct
  module Primary = struct
    type t = {
      job_artifacts_size : string option; [@default None]
      lfs_objects_size : string option; [@default None]
      packages_size : string option; [@default None]
      pipeline_artifacts_size : string option; [@default None]
      repository_size : string option; [@default None]
      snippets_size : string option; [@default None]
      storage_size : string option; [@default None]
      uploads_size : string option; [@default None]
      wiki_size : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t = {
  archived : bool option; [@default None]
  auto_devops_enabled : string option; [@default None]
  avatar_url : string option; [@default None]
  created_at : string;
  custom_attributes : Gitlabc_components_api_entities_customattribute.t option; [@default None]
  default_branch : string option; [@default None]
  default_branch_protection : Default_branch_protection.t option; [@default None]
  default_branch_protection_defaults : Default_branch_protection_defaults.t option; [@default None]
  description : string option; [@default None]
  duo_features_enabled : string option; [@default None]
  emails_disabled : bool option; [@default None]
  emails_enabled : bool option; [@default None]
  file_template_project_id : string option; [@default None]
  full_name : string option; [@default None]
  full_path : string option; [@default None]
  id : int;
  ldap_access : bool option; [@default None]
  ldap_cn : string option; [@default None]
  ldap_group_links : Gitlabc_components_ee_api_entities_ldapgrouplink.t option; [@default None]
  lfs_enabled : bool option; [@default None]
  lock_duo_features_enabled : bool option; [@default None]
  lock_math_rendering_limits_enabled : bool option; [@default None]
  marked_for_deletion_on : string option; [@default None]
  math_rendering_limits_enabled : bool option; [@default None]
  max_artifacts_size : int option; [@default None]
  mentions_disabled : Mentions_disabled.t option; [@default None]
  name : string;
  organization_id : int option; [@default None]
  parent_id : Parent_id.t option; [@default None]
  path : string option; [@default None]
  project_creation_level : string option; [@default None]
  repository_storage : string option; [@default None]
  request_access_enabled : bool option; [@default None]
  require_two_factor_authentication : bool option; [@default None]
  root_storage_statistics : Root_storage_statistics.t option; [@default None]
  saml_group_links : Saml_group_links.t option; [@default None]
  share_with_group_lock : bool option; [@default None]
  shared_runners_setting : string option; [@default None]
  statistics : Statistics.t option; [@default None]
  subgroup_creation_level : string option; [@default None]
  two_factor_grace_period : int option; [@default None]
  visibility : string option; [@default None]
  web_url : string option; [@default None]
  wiki_access_level : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
