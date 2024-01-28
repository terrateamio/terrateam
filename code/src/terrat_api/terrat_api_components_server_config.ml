type t = {
  github_app_client_id : string;
  github_app_url : string;
  github_web_base_url : string;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]
