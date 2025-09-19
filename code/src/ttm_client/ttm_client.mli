type create_err =
  [ `Refresh_token_err
  | `Missing_api_key_err
  | Openapic_abb.call_err
  ]
[@@deriving show]

type t

(** Create a new connection. If [api_key] is not specified, the environment variable [TTM_API_KEY]
    is used. It is assumed that the api key can be used for any operation, however if a
    [403 Forbidden] response is received, it tries to refresh the token and if that succeeds, using
    that token. *)
val create :
  ?call_timeout:float ->
  ?api_key:string ->
  base_url:Uri.t ->
  unit ->
  (t, [> create_err ]) result Abb.Future.t

val call :
  ?tries:int ->
  t ->
  'a Openapi.Request.t ->
  ('a Openapi.Response.t, [> create_err ]) result Abb.Future.t
