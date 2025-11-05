type t = {
  capabilities : Terrat_api_components_access_token_capabilities.t;
  name : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
