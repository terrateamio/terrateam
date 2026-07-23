(** A bounded executor runs at most [slots] user functions concurrently.

    {b Domain-safety:} cross-task communication uses the [Chan]-based request/reply pattern from RFD
    675 (via {!Abb_service_local}), so callers and the executor's server task may live on different
    domains. The user function passed to {!Make.run} is invoked on the server task's domain; any
    mutable state captured by its closure must be safe to access there. *)
module Make (S : Abb_intf.S) (Key : Map.OrderedType) (_ : Abb_time.Time_make(S.Future).S) : sig
  type t

  module Logger : sig
    type t = {
      exec_task : Key.t list -> unit;
      complete_task : Key.t list -> unit;
      work_done : Key.t list -> unit;
      running_tasks : int -> unit;
      enqueue : Key.t list -> unit;
      queue_time : float -> unit;
    }
  end

  val create : ?logger:Logger.t -> slots:int -> unit -> t S.Future.t
  val run : ?name:Key.t list -> t -> (unit -> 'a S.Future.t) -> 'a S.Future.t
end
