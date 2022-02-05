module Authorization : sig
  type t =
    [ `Token of string
    | `Bearer of string
    ]
end

type call_err =
  [ `Conversion_err of string * string Openapi.Response.t
  | `Missing_response of string Openapi.Response.t
  | `Error
  ]
[@@deriving show]

type t

val create : ?user_agent:string -> ?base_url:Uri.t -> Authorization.t -> t
val call : t -> 'a Openapi.Request.t -> ('a Openapi.Response.t, [> call_err ]) result Abb.Future.t

val collect_all :
  t -> [> `OK of 'a list ] Openapi.Request.t -> ('a list, [> call_err ]) result Abb.Future.t

val fold :
  t ->
  init:'a ->
  f:('a -> 'b Openapi.Response.t -> ('a, ([> call_err ] as 'e)) result Abb.Future.t) ->
  'b Openapi.Request.t ->
  ('a, 'e) result Abb.Future.t
