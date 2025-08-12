module Auto_devops_enabled = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Custom_attributes = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Default_branch_protection_defaults = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Enabled_git_access_protocol = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Mentions_disabled = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Parent_id = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Prevent_forking_outside_group = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Projects = struct
  module Items = struct
    type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Root_storage_statistics = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Saml_group_links = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Shared_projects = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Shared_with_groups = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Statistics = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  allowed_email_domains_list : string option; [@default None]
  archived : bool option; [@default None]
  auto_devops_enabled : Auto_devops_enabled.t option; [@default None]
  avatar_url : string option; [@default None]
  created_at : string;
  custom_attributes : Custom_attributes.t option; [@default None]
  default_branch : string option; [@default None]
  default_branch_protection_defaults : Default_branch_protection_defaults.t option; [@default None]
  description : string option; [@default None]
  enabled_git_access_protocol : Enabled_git_access_protocol.t option; [@default None]
  full_name : string option; [@default None]
  full_path : string option; [@default None]
  id : int;
  mentions_disabled : Mentions_disabled.t option; [@default None]
  name : string;
  organization_id : int option; [@default None]
  parent_id : Parent_id.t option; [@default None]
  path : string option; [@default None]
  prevent_forking_outside_group : Prevent_forking_outside_group.t option; [@default None]
  prevent_sharing_groups_outside_hierarchy : bool option; [@default None]
  project_creation_level : string option; [@default None]
  projects : Projects.t option; [@default None]
  root_storage_statistics : Root_storage_statistics.t option; [@default None]
  saml_group_links : Saml_group_links.t option; [@default None]
  share_with_group_lock : bool option; [@default None]
  shared_projects : Shared_projects.t option; [@default None]
  shared_runners_setting : string option; [@default None]
  shared_with_groups : Shared_with_groups.t option; [@default None]
  statistics : Statistics.t option; [@default None]
  visibility : string option; [@default None]
  web_url : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
