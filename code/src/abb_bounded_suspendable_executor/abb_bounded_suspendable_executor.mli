module Make
    (Fut : Abb_intf.Future.S)
    (Key : Map.OrderedType)
    (Time : Abb_time.Time_make(Fut).S) : sig
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

  val create : ?logger:Logger.t -> slots:int -> unit -> t Fut.t
  val run : name:Key.t list -> t -> (unit -> 'a Fut.t) -> 'a Fut.t
  val suspend : name:Key.t list -> t -> unit Fut.t
  val unsuspend : name:Key.t list -> t -> unit Fut.t
end
