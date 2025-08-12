type t = {
  author : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  note : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
