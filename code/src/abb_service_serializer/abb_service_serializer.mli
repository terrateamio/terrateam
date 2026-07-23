(** Serializes any function execution.

    Cross-task communication uses the request/reply-over-[Chan] pattern from RFD 675 (via
    {!Abb_service_local.Make_typed}), so callers and the server task may live on different domains.

    {b Domain-safety of [~f]:} the [~f] callback you pass to {!Make.run} is invoked on the server
    task's domain. Any mutable state your closure captures must be safe to access from there —
    typically that means only touching values created on the server's domain, immutable values, or
    atomics. Pure computations and ordinary database / API calls are fine; sharing a [ref] or
    [Hashtbl] with another task is not. *)

module Make (S : Abb_intf.S) : sig
  type msg
  type t = msg S.Chan.t

  val create : unit -> t S.Future.t

  (** Run [f] in the serializer's task and return the result. [`Closed] is returned when the service
      has been shut down. Exceptions raised by [f] propagate to the caller as an [`Exn] state on the
      returned future; aborts propagate as [`Aborted].

      {b Domain-safety:} [f] runs on the server task's domain. See the module-level note. *)
  val run : t -> f:(unit -> 'a S.Future.t) -> [ `Ok of 'a | `Closed ] S.Future.t

  module Mutex : sig
    type serializer = t
    type 'a t

    val create : serializer -> 'a -> 'a t

    (** Run [f] with exclusive access to the wrapped value. The value must itself be safe to access
        from the serializer task's domain — see the module-level domain-safety note. *)
    val run : 'a t -> f:('a -> 'b S.Future.t) -> [ `Ok of 'b | `Closed ] S.Future.t
  end
end
