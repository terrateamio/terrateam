module Ctx = Brtl_ctx
module Rspnc = Brtl_rspnc

module Pre_handler = struct
  type ret =
    | Cont of (unit, unit) Ctx.t
    | Stop of (unit, Rspnc.t) Ctx.t

  type t = ((unit, unit) Ctx.t -> ret Abb.Future.t)
end

module Post_handler = struct
  type t = ((string, Rspnc.t) Ctx.t -> (string, Rspnc.t) Ctx.t Abb.Future.t)
end

module Early_exit_handler = struct
  type t = ((unit, Rspnc.t) Ctx.t -> (unit, Rspnc.t) Ctx.t Abb.Future.t)
end


module Mw = struct
  type t = { pre_handler : Pre_handler.t
           ; post_handler : Post_handler.t
           ; early_exit_handler : Early_exit_handler.t
           }

  let create pre_handler post_handler early_exit_handler =
    { pre_handler; post_handler; early_exit_handler }
end

let pre_handler_noop ctx = Abb.Future.return (Pre_handler.Cont ctx)
let post_handler_noop = Abb.Future.return
let early_exit_handler_noop = Abb.Future.return

type t = Mw.t list

let create t = t

let rec exec_pre_handler ctx = function
  | [] ->
    Abb.Future.return (Pre_handler.Cont ctx)
  | h::hs ->
    let open Abb.Future.Infix_monad in
    h.Mw.pre_handler ctx
    >>= function
    | Pre_handler.Cont ctx ->
      exec_pre_handler ctx hs
    | Pre_handler.Stop _ as ret ->
      Abb.Future.return ret

let rec exec_post_handler ctx = function
  | [] ->
    Abb.Future.return ctx
  | h::hs ->
    let open Abb.Future.Infix_monad in
    h.Mw.post_handler ctx
    >>= fun ctx ->
    exec_post_handler ctx hs

let rec exec_early_exit_handler ctx = function
  | [] ->
    Abb.Future.return ctx
  | h::hs ->
    let open Abb.Future.Infix_monad in
    h.Mw.early_exit_handler ctx
    >>= fun ctx ->
    exec_early_exit_handler ctx hs
