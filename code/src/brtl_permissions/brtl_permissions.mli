module Permission : sig
  type ('a, 'b) t = (string, 'a) Brtl_ctx.t -> 'b -> bool Abb.Future.t
end

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
