module Permission : sig
  type ('a, 'b) t = (string, 'a) Brtl_ctx.t -> 'b -> bool Abb.Future.t
end

module Auth : sig
  type t = Bearer of string [@@deriving show]
end

type get_auth_err =
  [ `No_auth
  | `Unknown_auth of string
  ]
[@@deriving show]

val with_permissions :
  ('a, 'b) Permission.t list ->
  (string, 'a) Brtl_ctx.t ->
  'b ->
  (unit -> (string, Brtl_rspnc.t) Brtl_ctx.t Abb.Future.t) ->
  (string, Brtl_rspnc.t) Brtl_ctx.t Abb.Future.t

val with_permissions_ep :
  ('a, 'b) Permission.t list ->
  'b ->
  (string, 'a) Brtl_ctx.t ->
  ('a, [> `Forbidden ]) Brtl_ep.t Abb.Future.t

val get_auth : (string, 'a) Brtl_ctx.t -> (Auth.t, [> get_auth_err ]) result
