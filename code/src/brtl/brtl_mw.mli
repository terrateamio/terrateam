(** {1 Overview}

   Middleware allow code to be executed a various points in the system.  They
   are executed by the Brtl framework.  While any middleware handler may cause
   the termination of processing a request with an error, the {!Pre_handler.t}
   handler is the only one capable of short-circuiting processing, however it
   must set a response.  This allows for the implementation of middleware such
   as caches or redirects.

   Middleware is represented as an ordered collection of middleware instances.
   They are always processed in the same order for each handler.  That is to say
   a post-handler does not execute the handlers in the reverse order the
   pre-handler did. *)

(** The pre-handler is run before the body has been read from the request and
   before the handler has been executed.  It may short-circuit processing of the
   request by returning a response. *)
module Pre_handler : sig
  type ret =
    | Cont of (unit, unit) Brtl_ctx.t
    | Stop of (unit, Brtl_rspnc.t) Brtl_ctx.t

  type t = (unit, unit) Brtl_ctx.t -> ret Abb.Future.t
end

(** The post-handler is executed after executing the handler, if the handler
   executed successfully, but before writing the response out. *)
module Post_handler : sig
  type t = (string, Brtl_rspnc.t) Brtl_ctx.t -> (string, Brtl_rspnc.t) Brtl_ctx.t Abb.Future.t
end

(** The early-exit-handler is executed if the pre-handler has short-circuited
   processing of the request but before writing the response out..  It is run
   without a body but with a response. *)
module Early_exit_handler : sig
  type t = (unit, Brtl_rspnc.t) Brtl_ctx.t -> (unit, Brtl_rspnc.t) Brtl_ctx.t Abb.Future.t
end

(** Represents a single middleware instance. *)
module Mw : sig
  type t

  (** Given the various handlers, create the middleware. This is usually wrapped
     by the implementer of a middleware and a user of it rarely calls this
     function directly. *)
  val create : Pre_handler.t -> Post_handler.t -> Early_exit_handler.t -> t
end

(** A noop pre-handler. Does nothing. *)
val pre_handler_noop : Pre_handler.t

(** A noop post-handler. Does nothing. *)
val post_handler_noop : Post_handler.t

(** A noop early-exit-handler. Does nothing. *)
val early_exit_handler_noop : Early_exit_handler.t

(** An ordered collection of middleware. *)
type t

(** Create an ordered collection of middleware given a list of instances. *)
val create : Mw.t list -> t

(** Execute the pre-handlers.  No effort is made to handle errors and an error
   will result in remaining handlers not being executed.

   If a pre-handler decides to stop processing of the request, the remaining
   handlers are not executed.  For example, if logging an incoming handler is
   the last middleware to execute, an earlier one stopping execution will result
   in the logging middleware not executing. *)
val exec_pre_handler : (unit, unit) Brtl_ctx.t -> t -> Pre_handler.ret Abb.Future.t

(** Execute post-handlers in the same order as those executed by pre-handler. No
   effort is made to handle errors and an error will result in remaining
   handlers not being executed. *)
val exec_post_handler :
  (string, Brtl_rspnc.t) Brtl_ctx.t -> t -> (string, Brtl_rspnc.t) Brtl_ctx.t Abb.Future.t

(** Execute early-exit-handlers in the same order as those executed by
   pre-handler. No effort is made to handle errors and an error will result in
   remaining handlers not being executed.

   This is only run if the pre-handler decide to short-circuit the processing of
   a request.  Except in the case of an error, all handlers will be executed
   even if it was not executed as during pre-handling. *)
val exec_early_exit_handler :
  (unit, Brtl_rspnc.t) Brtl_ctx.t -> t -> (unit, Brtl_rspnc.t) Brtl_ctx.t Abb.Future.t
