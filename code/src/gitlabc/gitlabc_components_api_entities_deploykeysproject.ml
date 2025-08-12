type t = {
  can_push : bool option; [@default None]
  created_at : string option; [@default None]
  expires_at : string option; [@default None]
  fingerprint : string option; [@default None]
  fingerprint_sha256 : string option; [@default None]
  id : int option; [@default None]
  key : string option; [@default None]
  projects_with_readonly_access : Gitlabc_components_api_entities_projectidentity.t option;
      [@default None]
  projects_with_write_access : Gitlabc_components_api_entities_projectidentity.t option;
      [@default None]
  title : string option; [@default None]
  usage_type : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
