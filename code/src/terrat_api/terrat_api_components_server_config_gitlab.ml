type t = {
  api_base_url : string;
  app_id : string;
  redirect_url : string;
  web_base_url : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
