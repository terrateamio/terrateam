type t = {
  api_url : string option; [@default None]
  authorization_type : string option; [@default None]
  ca_cert : string option; [@default None]
  namespace : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
