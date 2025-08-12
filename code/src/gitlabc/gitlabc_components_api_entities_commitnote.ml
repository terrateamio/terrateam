type t = {
  author : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  created_at : string option; [@default None]
  line : int option; [@default None]
  line_type : string option; [@default None]
  note : string option; [@default None]
  path : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
