module Authorization : sig
  type t =
    [ `Token of string
    | `Bearer of string
    ]
end

type call_err =
  [ `Conversion_err of string * string Openapi.Response.t
  | `Missing_response of string Openapi.Response.t
  | `Io_err of Cohttp_abb.request_err
  | `Timeout
  ]
[@@deriving show]

type t

val create : ?user_agent:string -> ?base_url:Uri.t -> ?call_timeout:float -> Authorization.t -> t
val call : t -> 'a Openapi.Request.t -> ('a Openapi.Response.t, [> call_err ]) result Abb.Future.t

(** Iterate all of the pages in a paginated response and combine them.  They are
   returned in the order they were received. *)
val collect_all :
  t ->
  [> `OK of 'a list ] Openapi.Request.t ->
  ('a list, [> call_err | `Error ]) result Abb.Future.t

val fold :
  t ->
  init:'a ->
  f:('a -> 'b Openapi.Response.t -> ('a, ([> call_err ] as 'e)) result Abb.Future.t) ->
  'b Openapi.Request.t ->
  ('a, 'e) result Abb.Future.t
