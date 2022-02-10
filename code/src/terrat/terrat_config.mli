type t

type err =
  [ `Key_error of string
  | `Bad_pem of string
  ]

val show_err : err -> string
val create : unit -> (t, [> err ]) result
val frontend_port : t -> int
val backend_port : t -> int
val db_host : t -> string
val db_user : t -> string
val db_password : t -> string
val db : t -> string
val github_app_id : t -> string
val github_app_pem : t -> Mirage_crypto_pk.Rsa.priv
val github_webhook_secret : t -> string option
val github_app_client_secret : t -> string
val github_app_client_id : t -> string
val aws_account_id : t -> string
val aws_region : t -> string
val backend_address : t -> string
val atlantis_syslog_address : t -> string option
