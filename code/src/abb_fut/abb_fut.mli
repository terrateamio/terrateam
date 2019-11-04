(**

   {1 Overview}

   This module is based heavily on the {{:https://github.com/dbuenzli/fut} Fut}
   by Daniel Buenzli.

   This module provides an implementation of the future interface required by
   [Abb_intf.Future.S].  Futures are composed of two components: a [Promise] and
   a [Future].  A [Future] is a value that can be empty or contain another value
   and can only be set to a value once, becoming immutable.  By binding to a
   [Future] one can register interest in the value once set. A [Promise] is the
   mutable side of a [Future], providing an interface that can set the
   associated [Future].  A [Future] is generated from a [Promise] and its value
   can only be inspected.

   Combined, futures create a graph where each future can both depend on
   multiple futures and have multiple futures depending on it.

   Futures watching each other is how values propagate.  As the value for a
   future becomes available, those futures that depend on it can then be
   executed.  A future also has dependencies which are futures it depends on.
   For example, when calling {!Make.bind} on a future, a new future is made.
   This new future is a watcher for the original future and the new future
   depends on the original.  A [Future] can be stopped by calling {!Make.abort}
   or {!Make.cancel} on it.  If the future has been determined, the abortion is
   a no-op, otherwise the abort travels through the graph of futures and aborts
   all none determined futures connected to it, both those it is depending on
   and those watching it.  An abortion does not preempt an existing computation
   that will set a promise.  However the computation can check if the promise
   has been aborted.  Canceling a future only aborts it and those futures
   watching it and does not travel through the dependencies. Dependencies are
   created through the monadic and applicative combinators and can be explicitly
   added through {!Make.add_dep}.

   This implementation is greedy, in that it will try to execute as much work as
   can possibly be done.  This execution is not tail recursive.  The following
   code will result in blowing the stack:

   {[ let rec loop () = return () >>= fun () -> loop () ]}

   {1 What happens when a Promise gets set or aborted?}

   Setting a {!Make.Promise.t} creates a new future which, when determined, will
   determine that future and execute its watchers.  In the case of setting a
   value, the watchers will be called with the determined value, and in the case
   of aborting, will be called with a value marking it as aborted.

   In the case of a large graph that is aborted, it could take a considerable
   amount of time to abort every future.  At the moment, this library makes no
   effort to reduce the latency of aborting a large graph.

   {1 State}

   Executing futures has some underlying state information associated with it,
   this is created with [State.create].  This state information must be tracked
   by a user of the future's library and passed in to {!Make.run_with_state}.
   Users of the library can include their own state as well which is accessed
   through {!Make.with_state}.

   This should actually probably be implemented through a monad transformer
   combining state and concurrency monad but I'm not actually sure how to do
   that and threading it through manually seemed more straight forward. *)
module type S = sig
  type t
end

module State : sig
  type 'a t

  val create : 'a -> 'a t

  val state : 'a t -> 'a

  val set_state : 'a -> 'a t -> 'a t
end

module Make (Sched_state : S) : sig
  include Abb_intf.Future.S

  (** Run a future with a state, returning the new state.  The future is not
      guaranteed to be set after this return. *)
  val run_with_state : 'a t -> Sched_state.t State.t -> Sched_state.t State.t

  (** Modify the state and return it as well as a future. *)
  val with_state : (Sched_state.t State.t -> Sched_state.t State.t * 'a t) -> 'a t
end
