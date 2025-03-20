let default_telemetry_uri = Uri.of_string "https://telemetry.terrateam.io"
let default_terrateam_web_base_url = Uri.of_string "https://app.terrateam.io"

module Github = struct
  let default_github_api_base_url = Uri.of_string "https://api.github.com"
  let default_github_app_url = Uri.of_string "https://github.com/apps/terrateam-action"
  let default_github_web_base_url = Uri.of_string "https://github.com"

  type t = {
    api_base_url : Uri.t;
    app_client_id : string;
    app_client_secret : (string[@opaque]);
    app_id : string;
    app_pem : (Mirage_crypto_pk.Rsa.priv[@opaque]);
    app_url : Uri.t;
    web_base_url : Uri.t;
    webhook_secret : (string[@opaque]) option;
  }
  [@@deriving show]

  let api_base_url t = t.api_base_url
  let app_client_id t = t.app_client_id
  let app_client_secret t = t.app_client_secret
  let app_id t = t.app_id
  let app_pem t = t.app_pem
  let app_url t = t.app_url
  let web_base_url t = t.web_base_url
  let webhook_secret t = t.webhook_secret
end

module Telemetry = struct
  type t =
    | Disabled
    | Anonymous of Uri.t
  [@@deriving show]
end

module Infracost = struct
  type t = {
    api_key : string; [@opaque]
    endpoint : Uri.t;
  }
  [@@deriving show]
end

type t = {
  admin_token : string option;
  api_base : string;
  db : string;
  db_connect_timeout : float;
  db_host : string;
  db_max_pool_size : int;
  db_password : (string[@opaque]);
  db_user : string;
  github : Github.t option;
  infracost : Infracost.t option;
  nginx_status_uri : Uri.t option;
  port : int;
  python_exec : string;
  statement_timeout : string;
  telemetry : Telemetry.t;
  terrateam_web_base_url : Uri.t;
}
[@@deriving show]

type err =
  [ `Key_error of string
  | `Bad_pem of string
  ]
[@@deriving show]

let of_opt fail = function
  | Some v -> Ok v
  | None -> Error fail

let env_str key = of_opt (`Key_error key) (Sys.getenv_opt key)

let infracost () =
  let infracost_pricing_api_endpoint = Sys.getenv_opt "INFRACOST_PRICING_API_ENDPOINT" in
  let infracost_api_key = Sys.getenv_opt "SELF_HOSTED_INFRACOST_API_KEY" in
  match (infracost_pricing_api_endpoint, infracost_api_key) with
  | Some "", _ | _, Some "" -> None
  | Some endpoint, Some api_key -> Some { Infracost.endpoint = Uri.of_string endpoint; api_key }
  | _, _ -> None

let load_github () =
  let open CCResult.Infix in
  match Sys.getenv_opt "GITHUB_APP_ID" with
  | Some app_id ->
      let webhook_secret = Sys.getenv_opt "GITHUB_WEBHOOK_SECRET" in
      env_str "GITHUB_APP_PEM"
      >>= fun app_pem_content ->
      (match X509.Private_key.decode_pem (Cstruct.of_string app_pem_content) with
      | Ok (`RSA v) -> Ok v
      | Ok _ -> Error (`Bad_pem "Expected RSA")
      | Error (`Msg s) -> Error (`Bad_pem s))
      >>= fun app_pem ->
      env_str "GITHUB_APP_CLIENT_SECRET"
      >>= fun app_client_secret ->
      env_str "GITHUB_APP_CLIENT_ID"
      >>= fun app_client_id ->
      let api_base_url =
        CCOption.map_or
          ~default:Github.default_github_api_base_url
          Uri.of_string
          (Sys.getenv_opt "GITHUB_API_BASE_URL")
      in
      let web_base_url =
        CCOption.map_or
          ~default:Github.default_github_web_base_url
          Uri.of_string
          (Sys.getenv_opt "GITHUB_WEB_BASE_URL")
      in
      let app_url =
        CCOption.map_or
          ~default:Github.default_github_app_url
          Uri.of_string
          (Sys.getenv_opt "GITHUB_APP_URL")
      in
      Ok
        (Some
           {
             Github.api_base_url;
             app_client_id;
             app_client_secret;
             app_id;
             app_pem;
             app_url;
             web_base_url;
             webhook_secret;
           })
  | None -> Ok None

let create () =
  let open CCResult.Infix in
  of_opt
    (`Key_error "TERRAT_PORT")
    (CCInt.of_string (CCOption.get_or ~default:"8080" (Sys.getenv_opt "TERRAT_PORT")))
  >>= fun port ->
  env_str "DB_HOST"
  >>= fun db_host ->
  env_str "DB_USER"
  >>= fun db_user ->
  env_str "DB_PASS"
  >>= fun db_password ->
  env_str "DB_NAME"
  >>= fun db ->
  of_opt
    (`Key_error "DB_CONNECT_TIMEOUT")
    (CCFloat.of_string_opt (CCOption.get_or ~default:"120" (Sys.getenv_opt "DB_CONNECT_TIMEOUT")))
  >>= fun db_connect_timeout ->
  of_opt
    (`Key_error "DB_MAX_POOL_SIZE")
    (CCInt.of_string (CCOption.get_or ~default:"100" (Sys.getenv_opt "DB_MAX_POOL_SIZE")))
  >>= fun db_max_pool_size ->
  env_str "TERRAT_API_BASE"
  >>= fun api_base ->
  env_str "TERRAT_PYTHON_EXEC"
  >>= fun python_exec ->
  let infracost = infracost () in
  let nginx_status_uri = CCOption.map Uri.of_string (Sys.getenv_opt "NGINX_STATUS_URI") in
  let admin_token = Sys.getenv_opt "TERRAT_ADMIN_TOKEN" in
  let telemetry_uri =
    CCOption.map_or
      ~default:default_telemetry_uri
      Uri.of_string
      (Sys.getenv_opt "TERRAT_TELEMETRY_URI")
  in
  of_opt
    (`Key_error "TERRAT_TELEMETRY_LEVEL")
    (match CCOption.get_or ~default:"anonymous" (Sys.getenv_opt "TERRAT_TELEMETRY_LEVEL") with
    | "anonymous" -> Some (Telemetry.Anonymous telemetry_uri)
    | "disabled" -> Some Telemetry.Disabled
    | _ -> None)
  >>= fun telemetry ->
  let terrateam_web_base_url =
    CCOption.map_or
      ~default:default_terrateam_web_base_url
      Uri.of_string
      (Sys.getenv_opt "TERRAT_WEB_BASE_URL")
  in
  let statement_timeout =
    CCOption.get_or ~default:"500ms" (Sys.getenv_opt "TERRAT_STATEMENT_TIMEOUT")
  in
  load_github ()
  >>= fun github ->
  Ok
    {
      admin_token;
      api_base;
      db;
      db_connect_timeout;
      db_host;
      db_max_pool_size;
      db_password;
      db_user;
      github;
      infracost;
      nginx_status_uri;
      port;
      python_exec;
      statement_timeout;
      telemetry;
      terrateam_web_base_url;
    }

let admin_token t = t.admin_token
let api_base t = t.api_base
let db t = t.db
let db_connect_timeout t = t.db_connect_timeout
let db_host t = t.db_host
let db_max_pool_size t = t.db_max_pool_size
let db_password t = t.db_password
let db_user t = t.db_user
let github t = t.github
let infracost t = t.infracost
let nginx_status_uri t = t.nginx_status_uri
let port t = t.port
let python_exec t = t.python_exec
let statement_timeout t = t.statement_timeout
let telemetry t = t.telemetry
let terrateam_web_base_url t = t.terrateam_web_base_url
