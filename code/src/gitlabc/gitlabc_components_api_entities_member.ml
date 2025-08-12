type t = {
  access_level : int;
  avatar_path : string option; [@default None]
  avatar_url : string option; [@default None]
  created_at : string option; [@default None]
  created_by : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  email : string option; [@default None]
  expires_at : string option; [@default None]
  id : int option; [@default None]
  locked : bool option; [@default None]
  member_role : Gitlabc_components_ee_api_entities_memberrole.t option; [@default None]
  membership_state : string option; [@default None]
  name : string option; [@default None]
  state : string option; [@default None]
  username : string option; [@default None]
  web_url : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
