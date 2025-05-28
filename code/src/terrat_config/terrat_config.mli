module Github : sig
  type t [@@deriving show]

  val api_base_url : t -> Uri.t
  val app_client_id : t -> string
  val app_client_secret : t -> string
  val app_id : t -> string
  val app_pem : t -> Mirage_crypto_pk.Rsa.priv
  val app_url : t -> Uri.t
  val web_base_url : t -> Uri.t
  val webhook_secret : t -> string option
end

module Gitlab : sig
  type t [@@deriving show]

  val api_base_url : t -> Uri.t
  val app_id : t -> string
  val app_secret : t -> string
  val web_base_url : t -> Uri.t
end

type t [@@deriving show]

type err =
  [ `Key_error of string
  | `Bad_pem of string
  ]

module Telemetry : sig
  type t =
    | Disabled
    | Anonymous of Uri.t
end

module Infracost : sig
  type t = {
    api_key : string;
    endpoint : Uri.t;
  }
  [@@deriving show]
end

val admin_token : t -> string option
val api_base : t -> string
val create : unit -> (t, [> err ]) result
val db : t -> string
val db_connect_timeout : t -> float
val db_host : t -> string
val db_max_pool_size : t -> int
val db_password : t -> string
val db_user : t -> string
val default_tier : t -> string
val github : t -> Github.t option
val gitlab : t -> Gitlab.t option
val infracost : t -> Infracost.t option
val nginx_status_uri : t -> Uri.t option
val port : t -> int
val python_exec : t -> string
val show_err : err -> string
val statement_timeout : t -> string
val telemetry : t -> Telemetry.t
val terrateam_web_base_url : t -> Uri.t
