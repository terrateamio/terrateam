type t

type err =
  [ `Key_error of string
  | `Bad_pem of string
  ]

module Telemetry : sig
  type t =
    | Disabled
    | Anonymous of Uri.t
end

val admin_token : t -> string option
val api_base : t -> string
val create : unit -> (t, [> err ]) result
val db : t -> string
val db_connect_timeout : t -> float
val db_host : t -> string
val db_password : t -> string
val db_user : t -> string
val github_api_base_url : t -> Uri.t
val github_app_client_id : t -> string
val github_app_client_secret : t -> string
val github_app_id : t -> string
val github_app_pem : t -> Mirage_crypto_pk.Rsa.priv
val github_app_url : t -> Uri.t
val github_web_base_url : t -> Uri.t
val github_webhook_secret : t -> string option
val infracost_api_key : t -> string
val infracost_pricing_api_endpoint : t -> Uri.t
val nginx_status_uri : t -> Uri.t option
val port : t -> int
val python_exec : t -> string
val show_err : err -> string
val statement_timeout : t -> string
val telemetry : t -> Telemetry.t
val terrateam_web_base_url : t -> Uri.t
