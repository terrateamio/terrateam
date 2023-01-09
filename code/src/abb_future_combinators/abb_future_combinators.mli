(** Some common combinators over futures. *)
module Make (Fut : Abb_intf.Future.S) : sig
  (** A future that has been determined to the unit value. *)
  val unit : unit Fut.t

  (** Take a future value, wait for it to be determined and throw the value
      away. *)
  val ignore : 'a Fut.t -> unit Fut.t

  (** Take a future value and do not wait for it to finish before evaluating *)
  val background : 'a Fut.t -> unit Fut.t

  (** Takes two futures and return a tuple where the first element is the
      determined value of the first future to become determined and the second
      element is the undetermined future.  If both futures are determined, it is
      not defined which future will be which element of the tuple.

      If the call to [first] is aborted with [Fut.abort], the futures in the
      input are aborted as well. *)
  val first : 'a Fut.t -> 'a Fut.t -> ('a * 'a Fut.t) Fut.t

  (** Takes a list of futures and returns a tuple where the first element is the
      value of the first future to be determined and the second element is the
      list of undetermined futures remaining.  It is guaranteed that the length
      of the remaining list is one less than the length of the input list.  If
      more than one future is determined, which future is in the first element
      of the value is not guaranteed.  The order of the futures in the returned
      list is undefined.

      If the call to [firstl] is aborted with [Fut.abort], all of the futures in
      the input list are aborted.

      {e Warning:} Do not use this for large lists.  It is designed for small
      lists, and is intended to be used like a [select] function. *)
  val firstl : 'a Fut.t list -> ('a * 'a Fut.t list) Fut.t

  (** Takes a list of futures and returns a future of list of values.  These
      values are guaranteed to be in the same order as the input list.  The
      entire operation is failed if any of the futures fail due to an abort or
      exception.  All futures are aborted on failure or abort. *)
  val all : 'a Fut.t list -> 'a list Fut.t

  (** Execute a function which returns a future.  The [finally] function is
     executed:

      - If the function throws an exception.

      - If the Fut the function returns is successfully evaluated.

      - If the Fut is aborted or fails because of an exception.

      In all cases, the Fut is returned.  In the case of the function throwing
     an exception, a Fut will be returned that has been failed with the
     exception.

      If [finally] throws an exception then the future is failed with that
     exception.  In the case that the future had failed and calling [finally]
     throws an exception, the exception thrown by [finally] replaced the failure
     of the body and is propagated. *)
  val with_finally : (unit -> 'a Fut.t) -> finally:(unit -> unit Fut.t) -> 'a Fut.t

  (** Like {!with_finally} but it only execute the [failure] function if the
      future fails.  A failure is one of the following:

      - If the function throws an exception,
      - If the Fut is aborted or fails because of an exception.

      In all cases a Fut is returned.  In the case of an exception, a Fut is
      returned that has been failed with the exception.

      {b Note} it is undefined what happens if [finally] throws an exception or
      fails. *)
  val on_failure : (unit -> 'a Fut.t) -> failure:(unit -> unit Fut.t) -> 'a Fut.t

  (** Executes a future such that it is protected from any abort operation.  The
      future returned from this may still be aborted, however the work it is
      protecting will be executed to completion. *)
  val protect : (unit -> 'a Fut.t) -> 'a Fut.t

  (** Link two futures together.  If one is aborted or fails the other one will
      be aborted or failed. *)
  val link : 'a Fut.t -> 'b Fut.t -> unit

  (** Given a future, return a future containing a result that is always
     successful. *)
  val to_result : 'a Fut.t -> ('a, 'b) result Fut.t

  (** Given an option containing a future, return a future containing an
     option. *)
  val of_option : 'a Fut.t option -> 'a option Fut.t

  (** Perform an operation with a cancel future.  If the cancel future is
     determined first, the work is cancelled, if the work completes first the
     cancel future is cancelled. *)
  val with_cancel : cancel:unit Fut.t -> 'a Fut.t -> ('a, [> `Cancelled ]) result Fut.t

  (** Wait for a future to complete and if it does not in a specified time,
     abort it *)
  val timeout : timeout:unit Fut.t -> 'a Fut.t -> [ `Ok of 'a | `Timeout ] Fut.t

  (** Perform an operation [f], and call [while_] on the result.  If [while_]
      returns [true] it means to try again. If [false] then return the value.
      Otherwise run a function [betwixt] between runs and then call [f] again.
      Exceptions are not handled as part of the retry process. *)
  val retry : f:(unit -> 'a Fut.t) -> while_:('a -> bool) -> betwixt:('a -> unit Fut.t) -> 'a Fut.t

  (** Try, at most, the number of [tries] given.  If there are remaining tries,
      call the test function which corresponds to the [while_] in the {!retry}
      function. *)
  val finite_tries : int -> ('a -> bool) -> 'a -> bool

  module List : sig
    val map : f:('a -> 'b Fut.t) -> 'a list -> 'b list Fut.t
    val fold_left : f:('a -> 'b -> 'a Fut.t) -> init:'a -> 'b list -> 'a Fut.t

    (** Iterate a list of values executing a function in serial. *)
    val iter : f:('a -> unit Fut.t) -> 'a list -> unit Fut.t

    (** Iterate a list of values executing a function in parallel. *)
    val iter_par : f:('a -> unit Fut.t) -> 'a list -> unit Fut.t

    val filter : f:('a -> bool Fut.t) -> 'a list -> 'a list Fut.t
  end

  module List_result : sig
    val map : f:('a -> ('b, 'e) result Fut.t) -> 'a list -> ('b list, 'e) result Fut.t

    val fold_left :
      f:('a -> 'b -> ('a, 'e) result Fut.t) -> init:'a -> 'b list -> ('a, 'e) result Fut.t

    val iter : f:('a -> (unit, 'e) result Fut.t) -> 'a list -> (unit, 'e) result Fut.t
    val filter : f:('a -> (bool, 'e) result Fut.t) -> 'a list -> ('a list, 'e) result Fut.t
  end

  module Infix_result_monad : sig
    type ('a, 'b) t = ('a, 'b) result Fut.t

    val ( >>= ) : ('a, 'c) t -> ('a -> ('b, 'c) t) -> ('b, 'c) t
    val ( >>| ) : ('a, 'c) t -> ('a -> 'b) -> ('b, 'c) t
  end

  (** Applicative for result types.  Execute all futures and execute the given
     function or return the error value of the first future to evaluate to
     [Error _].  The results of any successes are discarded.  In the case of a
     future evaluating to [Error _], the other futures are NOT aborted. *)
  module Infix_result_app : sig
    type ('a, 'b) t = ('a, 'b) result Fut.t

    val ( <$> ) : ('a -> 'b) -> ('a, 'c) t -> ('b, 'c) t
    val ( <*> ) : ('a -> 'b, 'c) t -> ('a, 'c) t -> ('b, 'c) t
  end
end
