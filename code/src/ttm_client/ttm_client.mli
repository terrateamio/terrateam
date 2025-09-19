type create_err =
  [ `Refresh_token_err
  | `Missing_api_key_err
  | Openapic_abb.call_err
  ]
[@@deriving show]

type t

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
