(** Future / promise engine.

    See {{!Abb_intf.Future.S} the [Future.S] signature in [Abb_intf]} for the core
    monadic/applicative API; this module also threads a per-chain {!Sched_state.data} slot through
    each deferred chain so callers can group deferreds by it (e.g. trace or request ids). Use
    {!Make.set_data} to start a slice and {!Make.get_data} to read the current chain's value. *)
module type S = sig
  type t
  type data

  val zero_data : data
end

module State : sig
  type 'a t

  val create : 'a -> 'a t
  val state : 'a t -> 'a
  val set_state : 'a -> 'a t -> 'a t
end

module Make (Sched_state : S) : sig
  include Abb_intf.Future.S

  (** Run a future with a state, returning the new state. The future is not guaranteed to be set
      after this return. *)
  val run_with_state : 'a t -> Sched_state.t State.t -> Sched_state.t State.t

  (** Modify the state and return it as well as a future. *)
  val with_state : (Sched_state.t State.t -> Sched_state.t State.t * 'a t) -> 'a t

  (** [set_data v] returns a determined unit future whose chain-data slot is [v]. Every future
      constructed downstream of this in a [bind]/[map]/[app] chain inherits [v] until another
      [set_data] overrides it. *)
  val set_data : Sched_state.data -> unit t

  (** [get_data ()] returns a future that resolves to the current chain's data when scheduled.
      Constructed fresh on each call (a single shared future would freeze on first use). *)
  val get_data : unit -> Sched_state.data t

  (** Inspect the per-domain "current chain data" cell directly. Useful for debugging and for native
      helpers that need to capture the chain's data without going through a future. *)
  val peek_chain_data : unit -> Sched_state.data

  (** Register a printer for chain data that the debug build will invoke when it detects a
      cross-domain race on a [State]. The default printer reports "<no chain-data printer
      registered>".

      In release builds (compiled with [ABB_FUT_DEBUG=0], the default for the [release] profile)
      this is a no-op — the cross-domain check is preprocessed out entirely, so registered printers
      are never invoked.

      Schedulers that carry rich task identity in their chain data (e.g. task id + name) should
      install a printer at startup so debug-build diagnostics include that context. *)
  val set_debug_data_pp : (Sched_state.data -> string) -> unit
end
