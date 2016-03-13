module Action : sig
  module Flag : sig
    type t =
      | Add
      | Enable
      | Disable
      | Dispatch
      | Delete
      | Receipt
      | Oneshot
      | Clear
      | Eof
      | Error
  end

  type t

  val to_t : Flag.t list -> t
  val of_t : t -> Flag.t list
end

module Filter : sig
  module Read : sig
    type t = int
  end

  module Write : sig
    type t = int
  end

  module Vnode : sig
    module Flags : sig
      type f =
        | Delete
        | Write
        | Extend
        | Attrib
        | Link
        | Rename
        | Revoke

      type t

      val to_t : f list -> t
      val of_t : t -> f list
    end

    type t = { descr : int
             ; flags : Flags.t
             }
  end

  module Proc : sig
    module Flags : sig
      type f =
        | Exit
        | Fork
        | Exec
        | Track

      type t

      val to_t : f list -> t
      val of_t : t -> f list
    end

    type t = { pid : int
             ; flags : Flags.t
             }
  end

  module Signal : sig
    type t = int
  end

  module Timer : sig
    module Unit : sig
      type u =
        | Seconds
        | Mseconds
        | Useconds
        | Nseconds

      type t

      val to_t : u -> t
      val of_t : t -> u
    end

    type t = { id : int
             ; unit : Unit.t
             ; time : int
             }
  end

  module User : sig
    module Flags : sig
      type f =
        | Nop
        | And
        | Or
        | Copy
        | Ctrlmask
        | Fflagsmask
        | Trigger

      type t

      val to_t : f list -> t
      val of_t : t -> f list
    end

    type t = { id : int
             ; flags : Flags.t
             }
  end

  type t =
    | Read of Read.t
    | Write of Write.t
    | Vnode of Vnode.t
    | Proc of Proc.t
    | Signal of Signal.t
    | Timer of Timer.t
    | User of User.t
end

module Kevent : sig
  type t = Kqueue_bindings.Stubs(Kqueue_stubs).Kevent.t

  val set_from_filter : t -> Action.t -> Filter.t -> unit

  val of_filter : Action.t -> Filter.t -> t
  val to_filter : t -> (Action.t * Filter.t)
end

module Eventlist : sig
  type t

  val create : int -> t
  val null : t

  val capacity : t -> int
  val size : t -> int
  val set_size : t -> int -> unit

  val set_from_list : t -> Kevent.t list -> unit

  val of_list : Kevent.t list -> t
  val to_list : t -> Kevent.t list

  val fold : f:('a -> Kevent.t -> 'a) -> init:'a -> t -> 'a
  val iter : f:(Kevent.t -> unit) -> t -> unit
end

module Timeout : sig
  type t

  val create : sec:int -> nsec:int -> t
end

type t

(*
 * Create a new kqueue
*)
val create : unit -> t

(*
 * This is a direct mapping to the kqueue call in FreeBSD except that for how the
 * size of [changelist] and [eventlist] are affected.  In the call, the [size] of
 * [changelist] is used as input, and the [capacity] of [eventlist] is used as
 * input.  In output, if the call to [kevent] was successful, the size of
 * [eventlist] will be set to the return value of [kevent].  On error, the size
 * of [eventlist] is set to 0.  This is to make it impossible to access outside
 * those events that were set by the [kqueue] call.  In all cases, the return of
 * [kevent] is returned unaltered.
 *)
val kevent :
  t ->
  changelist:Eventlist.t ->
  eventlist:Eventlist.t ->
  timeout:Timeout.t option ->
  int
