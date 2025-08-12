module Custom_attributes = struct
  type t = Gitlabc_components_api_entities_customattribute.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Identities = struct
  type t = Gitlabc_components_api_entities_identity.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Scim_identities = struct
  type t = Gitlabc_components_api_entities_scimidentity.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  avatar_path : string option; [@default None]
  avatar_url : string option; [@default None]
  bio : string option; [@default None]
  bot : bool option; [@default None]
  can_create_group : bool option; [@default None]
  can_create_project : bool option; [@default None]
  color_scheme_id : int option; [@default None]
  commit_email : string option; [@default None]
  confirmed_at : string option; [@default None]
  created_at : string;
  current_sign_in_at : string option; [@default None]
  custom_attributes : Custom_attributes.t option; [@default None]
  discord : string option; [@default None]
  email : string option; [@default None]
  external_ : bool option; [@default None] [@key "external"]
  extra_shared_runners_minutes_limit : string option; [@default None]
  followers : string option; [@default None]
  following : string option; [@default None]
  id : int;
  identities : Identities.t option; [@default None]
  is_followed : string option; [@default None]
  job_title : string option; [@default None]
  last_activity_on : string option; [@default None]
  last_sign_in_at : string option; [@default None]
  linkedin : string option; [@default None]
  local_time : string option; [@default None]
  location : string option; [@default None]
  locked : bool option; [@default None]
  name : string option; [@default None]
  organization : string option; [@default None]
  private_profile : bool option; [@default None]
  projects_limit : int option; [@default None]
  pronouns : string option; [@default None]
  public_email : string option; [@default None]
  scim_identities : Scim_identities.t option; [@default None]
  shared_runners_minutes_limit : string option; [@default None]
  skype : string option; [@default None]
  state : string option; [@default None]
  theme_id : int option; [@default None]
  twitter : string option; [@default None]
  two_factor_enabled : bool option; [@default None]
  username : string;
  web_url : string option; [@default None]
  website_url : string option; [@default None]
  work_information : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
