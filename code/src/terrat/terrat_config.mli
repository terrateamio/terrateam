type t

type err =
  [ `Key_error of string
  | `Bad_pem of string
  ]

val show_err : err -> string
val create : unit -> (t, [> err ]) result
val port : t -> int
val db_host : t -> string
val db_user : t -> string
val db_password : t -> string
val db : t -> string
val github_app_id : t -> string
val github_app_pem : t -> Mirage_crypto_pk.Rsa.priv
val github_webhook_secret : t -> string option
val github_app_client_secret : t -> string
val github_app_client_id : t -> string
val api_base : t -> string
val python_exec : t -> string
val infracost_pricing_api_endpoint : t -> Uri.t
val infracost_api_key : t -> string
val db_connect_timeout : t -> float
val nginx_status_uri : t -> Uri.t option
val admin_token : t -> string option
