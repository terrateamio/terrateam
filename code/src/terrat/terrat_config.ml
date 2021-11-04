type t = {
  frontend_port : int;
  backend_port : int;
  db_host : string;
  db_user : string;
  db_password : string;
  db : string;
  github_app_id : string;
  github_app_pem : Mirage_crypto_pk.Rsa.priv;
  github_webhook_secret : string option;
  github_app_client_secret : string;
  github_app_client_id : string;
  aws_account_id : string;
  aws_region : string;
  backend_address : string;
}

type err =
  [ `Key_error of string
  | `Bad_pem   of string
  ]
[@@deriving show]

let of_opt fail = function
  | Some v -> Ok v
  | None   -> Error fail

let env_str key = of_opt (`Key_error key) (Sys.getenv_opt key)

let create () =
  let open CCResult.Infix in
  of_opt
    (`Key_error "TERRAT_FRONTEND_PORT")
    (CCInt.of_string (CCOpt.get_or ~default:"8080" (Sys.getenv_opt "TERRAT_FRONTEND_PORT")))
  >>= fun frontend_port ->
  of_opt
    (`Key_error "TERRAT_BACKEND_PORT")
    (CCInt.of_string (CCOpt.get_or ~default:"8081" (Sys.getenv_opt "TERRAT_BACKEND_PORT")))
  >>= fun backend_port ->
  env_str "DB_HOST"
  >>= fun db_host ->
  env_str "DB_USER"
  >>= fun db_user ->
  env_str "DB_PASS"
  >>= fun db_password ->
  env_str "DB_NAME"
  >>= fun db ->
  env_str "GITHUB_APP_ID"
  >>= fun github_app_id ->
  let github_webhook_secret = Sys.getenv_opt "GITHUB_WEBHOOK_SECRET" in
  env_str "GITHUB_APP_PEM"
  >>= fun github_app_pem_content ->
  (match X509.Private_key.decode_pem (Cstruct.of_string github_app_pem_content) with
    | Ok (`RSA v)    -> Ok v
    | Ok _           -> Error (`Bad_pem "Expected RSA")
    | Error (`Msg s) -> Error (`Bad_pem s))
  >>= fun github_app_pem ->
  env_str "GITHUB_APP_CLIENT_SECRET"
  >>= fun github_app_client_secret ->
  env_str "GITHUB_APP_CLIENT_ID"
  >>= fun github_app_client_id ->
  env_str "AWS_ACCOUNT_ID"
  >>= fun aws_account_id ->
  env_str "AWS_REGION"
  >>= fun aws_region ->
  env_str "BACKEND_ADDRESS"
  >>= fun backend_address ->
  Ok
    {
      frontend_port;
      backend_port;
      db_host;
      db_user;
      db_password;
      db;
      github_app_id;
      github_app_pem;
      github_webhook_secret;
      github_app_client_secret;
      github_app_client_id;
      aws_account_id;
      aws_region;
      backend_address;
    }

let frontend_port t = t.frontend_port

let backend_port t = t.backend_port

let db_host t = t.db_host

let db_user t = t.db_user

let db_password t = t.db_password

let db t = t.db

let github_app_id t = t.github_app_id

let github_app_pem t = t.github_app_pem

let github_webhook_secret t = t.github_webhook_secret

let github_app_client_secret t = t.github_app_client_secret

let github_app_client_id t = t.github_app_client_id

let aws_account_id t = t.aws_account_id

let aws_region t = t.aws_region

let backend_address t = t.backend_address
