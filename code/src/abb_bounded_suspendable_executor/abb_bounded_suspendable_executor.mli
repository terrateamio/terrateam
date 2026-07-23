(** A bounded executor with suspend/unsuspend semantics. Up to [slots] tasks run concurrently; a
    task can be suspended (held back even if a slot is free) and later unsuspended.

    {b Domain-safety:} cross-task communication uses the [Chan]-based request/reply pattern from RFD
    675 (via {!Abb_service_local}), so callers and the executor's server task may live on different
    domains. The user function passed to {!Make.run} is invoked on the server task's domain; any
    mutable state captured by its closure must be safe to access there. *)
module Make (S : Abb_intf.S) (Key : Map.OrderedType) : sig
  type t

  module Logger : sig
    type t = {
      exec_task : Key.t list -> unit;
      complete_task : Key.t list -> unit;
      work_done : Key.t list -> unit;
      running_tasks : int -> unit;
      suspended_tasks : int -> Key.t list Iter.t -> unit;
      suspend_task : Key.t list -> unit;
      unsuspend_task : Key.t list -> unit;
      enqueue : Key.t list -> unit;
      queue_time : float -> unit;
    }
  end

  val create : ?logger:Logger.t -> slots:int -> unit -> t S.Future.t
  val run : name:Key.t list -> t -> (unit -> 'a S.Future.t) -> 'a S.Future.t
  val suspend : name:Key.t list -> t -> unit S.Future.t
  val unsuspend : name:Key.t list -> t -> unit S.Future.t
end
