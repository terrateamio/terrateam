type t = {
  extern_uid : string option; [@default None]
  provider : string option; [@default None]
  saml_provider_id : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
