module Primary = struct
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
    allowed_email_domains_list : string option; [@default None]
    auto_ban_user_on_excessive_projects_download : string option; [@default None]
    auto_devops_enabled : string option; [@default None]
    avatar_url : string option; [@default None]
    created_at : string option; [@default None]
    custom_attributes : Gitlabc_components_api_entities_customattribute.t option; [@default None]
    default_branch : string option; [@default None]
    default_branch_protection : string option; [@default None]
    default_branch_protection_defaults : string option; [@default None]
    description : string option; [@default None]
    duo_features_enabled : string option; [@default None]
    emails_disabled : bool option; [@default None]
    emails_enabled : bool option; [@default None]
    enabled_git_access_protocol : string option; [@default None]
    extra_shared_runners_minutes_limit : string option; [@default None]
    file_template_project_id : string option; [@default None]
    full_name : string option; [@default None]
    full_path : string option; [@default None]
    id : string option; [@default None]
    ip_restriction_ranges : string option; [@default None]
    ldap_access : string option; [@default None]
    ldap_cn : string option; [@default None]
    ldap_group_links : Gitlabc_components_ee_api_entities_ldapgrouplink.t option; [@default None]
    lfs_enabled : string option; [@default None]
    lock_duo_features_enabled : string option; [@default None]
    lock_math_rendering_limits_enabled : bool option; [@default None]
    marked_for_deletion_on : string option; [@default None]
    math_rendering_limits_enabled : bool option; [@default None]
    max_artifacts_size : int option; [@default None]
    membership_lock : string option; [@default None]
    mentions_disabled : string option; [@default None]
    name : string option; [@default None]
    organization_id : string option; [@default None]
    parent_id : string option; [@default None]
    path : string option; [@default None]
    prevent_forking_outside_group : string option; [@default None]
    prevent_sharing_groups_outside_hierarchy : string option; [@default None]
    project_creation_level : string option; [@default None]
    projects : Gitlabc_components_api_entities_project.t option; [@default None]
    repository_storage : string option; [@default None]
    request_access_enabled : string option; [@default None]
    require_two_factor_authentication : string option; [@default None]
    root_storage_statistics :
      Gitlabc_components_api_entities_namespace_rootstoragestatistics.t option;
        [@default None]
    runners_token : string option; [@default None]
    saml_group_links : Gitlabc_components_ee_api_entities_samlgrouplink.t option; [@default None]
    service_access_tokens_expiration_enforced : string option; [@default None]
    share_with_group_lock : string option; [@default None]
    shared_projects : Gitlabc_components_api_entities_project.t option; [@default None]
    shared_runners_minutes_limit : string option; [@default None]
    shared_runners_setting : string option; [@default None]
    shared_with_groups : string option; [@default None]
    statistics : Statistics.t option; [@default None]
    subgroup_creation_level : string option; [@default None]
    two_factor_grace_period : string option; [@default None]
    unique_project_download_limit : string option; [@default None]
    unique_project_download_limit_alertlist : string option; [@default None]
    unique_project_download_limit_allowlist : string option; [@default None]
    unique_project_download_limit_interval_in_seconds : string option; [@default None]
    visibility : string option; [@default None]
    web_url : string option; [@default None]
    wiki_access_level : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
