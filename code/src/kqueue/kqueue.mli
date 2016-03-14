module Event = Kqueue_event
module Change = Kqueue_change

module Eventlist : sig
  type t

  val create : int -> t
  val null : t

  val capacity : t -> int
  val size : t -> int
  val set_size : t -> int -> unit

  val set_from_list : t -> Kqueue_bindings.Stubs(Kqueue_stubs).Kevent.t list -> unit

  val of_list : Kqueue_bindings.Stubs(Kqueue_stubs).Kevent.t list -> t
  val to_list : t -> Kqueue_bindings.Stubs(Kqueue_stubs).Kevent.t list

  val fold : f:('a -> Kqueue_bindings.Stubs(Kqueue_stubs).Kevent.t -> 'a) -> init:'a -> t -> 'a
  val iter : f:(Kqueue_bindings.Stubs(Kqueue_stubs).Kevent.t -> unit) -> t -> unit
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
