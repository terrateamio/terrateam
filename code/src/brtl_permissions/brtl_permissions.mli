module Permission : sig
  type 'a t = ('a -> bool Abb.Future.t)
end

val with_permissions :
  'a Permission.t list ->
  (string, unit) Brtl_ctx.t ->
  'a ->
  (unit -> (string, Brtl_rspnc.t) Brtl_ctx.t Abb.Future.t) ->
  (string, Brtl_rspnc.t) Brtl_ctx.t Abb.Future.t
