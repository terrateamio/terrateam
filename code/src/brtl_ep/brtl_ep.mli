type ('s, 'f) t = ((string, 's) Brtl_ctx.t, (string, 'f) Brtl_ctx.t) result

val run :
  on_failure:((string, 'f) Brtl_ctx.t -> (string, Brtl_rspnc.t) Brtl_ctx.t) ->
  f:((string, unit) Brtl_ctx.t -> (Brtl_rspnc.t, 'f) t Abb.Future.t) ->
  Brtl_rtng.Handler.t

module Infix : sig
  val (@-->) :
    ((string, 'a) Brtl_ctx.t -> ('s1, 'f) t Abb.Future.t) ->
    ((string, 's1) Brtl_ctx.t -> ('s2, 'f) t Abb.Future.t) ->
    (string, 'a) Brtl_ctx.t ->
    ('s2, 'f) t Abb.Future.t
end
