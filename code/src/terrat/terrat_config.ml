type t = {
  port : int;
  db_host : string;
  db_user : string;
  db_password : string;
  db : string;
  github_app_id : string;
  github_app_pem : Mirage_crypto_pk.Rsa.priv;
  github_webhook_secret : string option;
  github_app_client_secret : string;
  github_app_client_id : string;
  api_base : string;
  python_exec : string;
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
  Ok
    {
      port;
      db_host;
      db_user;
      db_password;
      db;
      github_app_id;
      github_app_pem;
      github_webhook_secret;
      github_app_client_secret;
      github_app_client_id;
      api_base;
      python_exec;
    }

let port t = t.port
let db_host t = t.db_host
let db_user t = t.db_user
let db_password t = t.db_password
let db t = t.db
let github_app_id t = t.github_app_id
let github_app_pem t = t.github_app_pem
let github_webhook_secret t = t.github_webhook_secret
let github_app_client_secret t = t.github_app_client_secret
let github_app_client_id t = t.github_app_client_id
let api_base t = t.api_base
let python_exec t = t.python_exec
