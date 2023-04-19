let default_telemetry_uri = Uri.of_string "https://telemetry.terrateam.io"

module Telemetry = struct
  type t =
    | Disabled
    | Anonymous of Uri.t
end

type t = {
  port : int;
  db_host : string;
  db_user : string;
  db_password : string;
  db : string;
  db_connect_timeout : float;
  github_app_id : string;
  github_app_pem : Mirage_crypto_pk.Rsa.priv;
  github_webhook_secret : string option;
  github_app_client_secret : string;
  github_app_client_id : string;
  api_base : string;
  python_exec : string;
  infracost_pricing_api_endpoint : Uri.t;
  infracost_api_key : string;
  nginx_status_uri : Uri.t option;
  admin_token : string option;
  telemetry : Telemetry.t;
}

type err =
  [ `Key_error of string
  | `Bad_pem of string
  ]
[@@deriving show]

let of_opt fail = function
  | Some v -> Ok v
  | None -> Error fail

let env_str key = of_opt (`Key_error key) (Sys.getenv_opt key)

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
  env_str "GITHUB_APP_ID"
  >>= fun github_app_id ->
  let github_webhook_secret = Sys.getenv_opt "GITHUB_WEBHOOK_SECRET" in
  env_str "GITHUB_APP_PEM"
  >>= fun github_app_pem_content ->
  (match X509.Private_key.decode_pem (Cstruct.of_string github_app_pem_content) with
  | Ok (`RSA v) -> Ok v
  | Ok _ -> Error (`Bad_pem "Expected RSA")
  | Error (`Msg s) -> Error (`Bad_pem s))
  >>= fun github_app_pem ->
  env_str "GITHUB_APP_CLIENT_SECRET"
  >>= fun github_app_client_secret ->
  env_str "GITHUB_APP_CLIENT_ID"
  >>= fun github_app_client_id ->
  env_str "TERRAT_API_BASE"
  >>= fun api_base ->
  env_str "TERRAT_PYTHON_EXEC"
  >>= fun python_exec ->
  env_str "INFRACOST_PRICING_API_ENDPOINT"
  >>= fun infracost_pricing_api_endpoint ->
  env_str "SELF_HOSTED_INFRACOST_API_KEY"
  >>= fun infracost_api_key ->
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
  Ok
    {
      port;
      db_host;
      db_user;
      db_password;
      db;
      db_connect_timeout;
      github_app_id;
      github_app_pem;
      github_webhook_secret;
      github_app_client_secret;
      github_app_client_id;
      api_base;
      python_exec;
      infracost_pricing_api_endpoint = Uri.of_string infracost_pricing_api_endpoint;
      infracost_api_key;
      nginx_status_uri;
      admin_token;
      telemetry;
    }

let port t = t.port
let db_host t = t.db_host
let db_user t = t.db_user
let db_password t = t.db_password
let db t = t.db
let db_connect_timeout t = t.db_connect_timeout
let github_app_id t = t.github_app_id
let github_app_pem t = t.github_app_pem
let github_webhook_secret t = t.github_webhook_secret
let github_app_client_secret t = t.github_app_client_secret
let github_app_client_id t = t.github_app_client_id
let api_base t = t.api_base
let python_exec t = t.python_exec
let infracost_pricing_api_endpoint t = t.infracost_pricing_api_endpoint
let infracost_api_key t = t.infracost_api_key
let nginx_status_uri t = t.nginx_status_uri
let admin_token t = t.admin_token
let telemetry t = t.telemetry
