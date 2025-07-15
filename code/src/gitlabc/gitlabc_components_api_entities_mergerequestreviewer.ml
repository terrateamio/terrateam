type t = {
  created_at : string option; [@default None]
  state : string option; [@default None]
  user : Gitlabc_components_api_entities_userbasic.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
