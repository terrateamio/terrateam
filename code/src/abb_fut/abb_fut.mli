(** {1 Overview}

    This module is based heavily on the {{:https://github.com/dbuenzli/fut} Fut}
    by Daniel Buenzli.

    This module provides an implementation of the future interface required by
    [Abb_intf.Future.S].  Futures are composed of two components: a [Promise]
    and a [Future].  A [Future] is a value that can be empty or contain another
    value and can only be set to a value once, becoming immutable.  By binding
    to a [Future] one can register interest in the value once set. A [Promise]
    is the mutable side of a [Future], providing an interface that can set the
    associated [Future].  A [Future] is generated from a [Promise] and its value
    can only be inspected.

    Combined, futures create a graph where each future can both depend on
    multiple futures and have multiple futures depending on it.

    Futures depending on each other is how values propagate.  As the value for a
    future becomes available, those futures that depend on it can now execute.
    A [Future] can be aborted by calling {!abort} on it.  If the future has been
    determined, the abortion is a no-op, otherwise the abort travels through the
    graph of futures and aborts all none determined futures connected to it,
    both those it is depending on and those depending on it.  An abortion does
    not preempt an existing computation that will set a promise.  However the
    computation can check if the promise has been aborted.  Dependencies are
    created through the monadic and applicative combinators.

    {1 What happens when a Promise gets set?}

    Setting a {!Promise.t} makes it determined and will execute those futures
    that are waiting on it.  The following steps happen in order:

    - The state of the dependency is updated to reflect that it has been
    determined with a value.
    - It's deregistered as a dependency from those futures it depends on.
    - All its dependents are executed with the determined value.

    {1 What happens when a Future gets aborted?}

    - The state of the future is changed to reflect that it has been aborted.
    - The abort function for the future is executed.
    - The future is removed from the dependent list of all its dependencies.
    - The dependent futures are evaluated as aborted.
    - The dependencies are evaluated as aborted.

    The abort flows through dependencies and dependents, aborting everything
    along the way.

    In the case of a large graph that is aborted, it could take a considerable
    amount of time to abort every future.  At the moment, this library makes no
    effort to reduce the latency of aborting a large graph.

    {1 State}

    Executing futures has some underlying state information associated with it,
    this is created with [State.create].  This state information must be tracked
    by a user of the future's library and passed in to {!run_with_state}.
    Keeping any state information local allows the library to be safely used in
    a multi-threaded environment. *)
module State : sig
  type t
  val create : unit -> t
end

include Abb_intf.Future.S

(** Run a future with a state, returning the new state.  The future is not
    guaranteed to be set after this return. *)
val run_with_state : 'a t -> State.t -> State.t
