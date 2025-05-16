type t = {
  api_base_url : string;
  app_client_id : string;
  app_url : string;
  web_base_url : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
