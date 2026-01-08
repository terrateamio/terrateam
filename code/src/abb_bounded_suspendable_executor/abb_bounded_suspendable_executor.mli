module Make (Fut : Abb_intf.Future.S) (Key : Map.OrderedType) : sig
  type t

  module Logger : sig
    type t = {
      exec_task : Key.t list -> unit;
      complete_task : Key.t list -> unit;
      work_done : Key.t list -> unit;
      running_tasks : int -> unit;
      suspend_task : Key.t list -> unit;
      unsuspend_task : Key.t list -> unit;
      enqueue : Key.t list -> unit;
    }
  end

  val create : ?logger:Logger.t -> slots:int -> unit -> t Fut.t
  val run : name:Key.t list -> t -> (unit -> 'a Fut.t) -> 'a Fut.t
  val suspend : name:Key.t list -> t -> unit Fut.t
  val unsuspend : name:Key.t list -> t -> unit Fut.t
end
