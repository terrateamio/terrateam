type t = {
  avatar_url : string option; [@default None]
  created_at : string option; [@default None]
  default_branch : string;
  description : string option; [@default None]
  id : int;
  name : string option; [@default None]
  name_with_namespace : string option; [@default None]
  namespace : Gitlabc_components_api_entities_namespacebasic.t option; [@default None]
  owner : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  path : string option; [@default None]
  path_with_namespace : string;
  updated_at : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
