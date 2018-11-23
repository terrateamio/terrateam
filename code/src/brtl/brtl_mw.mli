module Pre_handler : sig
  type ret =
    | Cont of (unit, unit) Brtl_ctx.t
    | Stop of (unit, Brtl_rspnc.t) Brtl_ctx.t

  type t = ((unit, unit) Brtl_ctx.t -> ret Abb.Future.t)
end

module Post_handler : sig
  type t = ((string, Brtl_rspnc.t) Brtl_ctx.t ->
            (string, Brtl_rspnc.t) Brtl_ctx.t Abb.Future.t)
end

module Early_exit_handler : sig
  type t = ((unit, Brtl_rspnc.t) Brtl_ctx.t ->
            (unit, Brtl_rspnc.t) Brtl_ctx.t Abb.Future.t)
end

module Mw : sig
  type t
  val create : Pre_handler.t -> Post_handler.t -> Early_exit_handler.t -> t
end

val pre_handler_noop : Pre_handler.t
val post_handler_noop : Post_handler.t
val early_exit_handler_noop : Early_exit_handler.t

type t

val create : Mw.t list -> t

val exec_pre_handler : (unit, unit) Brtl_ctx.t -> t -> Pre_handler.ret Abb.Future.t

val exec_post_handler :
  (string, Brtl_rspnc.t) Brtl_ctx.t ->
  t ->
  (string, Brtl_rspnc.t) Brtl_ctx.t Abb.Future.t

val exec_early_exit_handler :
  (unit, Brtl_rspnc.t) Brtl_ctx.t ->
  t ->
  (unit, Brtl_rspnc.t) Brtl_ctx.t Abb.Future.t

