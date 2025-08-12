type t = {
  created_at : string option; [@default None]
  destination_storage_name : string option; [@default None]
  error_message : string option; [@default None]
  id : int option; [@default None]
  project : Gitlabc_components_api_entities_projectidentity.t option; [@default None]
  source_storage_name : string option; [@default None]
  state : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
