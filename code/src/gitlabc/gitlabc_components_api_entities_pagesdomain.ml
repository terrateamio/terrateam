type t = {
  auto_ssl_enabled : bool option; [@default None]
  certificate : Gitlabc_components_api_entities_pagesdomaincertificate.t option; [@default None]
  domain : string option; [@default None]
  enabled_until : string option; [@default None]
  url : string option; [@default None]
  verification_code : string option; [@default None]
  verified : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
