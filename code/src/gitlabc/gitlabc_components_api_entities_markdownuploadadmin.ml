type t = {
  created_at : string option; [@default None]
  filename : string option; [@default None]
  id : string option; [@default None]
  size : string option; [@default None]
  uploaded_by : Gitlabc_components_api_entities_usersafe.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
