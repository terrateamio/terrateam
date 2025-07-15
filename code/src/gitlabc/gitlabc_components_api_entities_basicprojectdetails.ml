module Tag_list = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Topics = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  avatar_url : string option; [@default None]
  created_at : string option; [@default None]
  custom_attributes : Gitlabc_components_api_entities_customattribute.t option; [@default None]
  default_branch : string option; [@default None]
  description : string option; [@default None]
  forks_count : int option; [@default None]
  http_url_to_repo : string option; [@default None]
  id : int option; [@default None]
  last_activity_at : string option; [@default None]
  license : Gitlabc_components_api_entities_licensebasic.t option; [@default None]
  license_url : string option; [@default None]
  name : string option; [@default None]
  name_with_namespace : string option; [@default None]
  namespace : Gitlabc_components_api_entities_namespacebasic.t option; [@default None]
  path : string option; [@default None]
  path_with_namespace : string option; [@default None]
  readme_url : string option; [@default None]
  repository_storage : string option; [@default None]
  ssh_url_to_repo : string option; [@default None]
  star_count : int option; [@default None]
  tag_list : Tag_list.t option; [@default None]
  topics : Topics.t option; [@default None]
  web_url : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
