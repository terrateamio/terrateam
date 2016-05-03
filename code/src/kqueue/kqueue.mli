(** [Kqueue] implements bindings to the BSD {{:
    https://www.freebsd.org/cgi/man.cgi?query=kqueue&apropos=0&sektion=0&manpath=FreeBSD+10.3-RELEASE&arch=default&format=html
    } kqueue} interface.  The bindings provide a type-safe interface as well as
    a raw interface to the the system call. *)

module Event = Kqueue_event
module Change = Kqueue_change

(** An [Eventlist] is to both set events that should be listened on, called a {e
    changelist } as well as where reported events are put into, called an {e
    eventlist}.  An [Eventlist] is an allocated sequence of [struct kevent]s
    that has a capacity and a size where the size is less-than or equal to the
    capacity.  An [Eventlist] can be created from, and converted, to a list as
    well as filled in from a list that is not larger than the capacity. *)
module Eventlist : sig
  type t

  (** Create an [Eventlist] with a capacity and size of the input value *)
  val create : int -> t

  (** A [null] [Eventlist] is an unallocated [Eventlist].  It has a capacity of
      zero.  This is used where [NULL] would be passed in to [kqueue]. *)
  val null : t

  val capacity : t -> int
  val size : t -> int

  (** Set the size of the [Eventlist].

      @raise Assertion_failue when the size being set is greater than the
      capacity. *)
  val set_size : t -> int -> unit

  (** Copy the elements of a list into the [Eventlist].  The size is set to the
      legnth of the list.

      @raise Assertion_failure when the size being set is greater than the
      capacity.  *)
  val set_from_list : t -> Kqueue_bindings.Stubs(Kqueue_stubs).Kevent.t list -> unit

  val of_list : Kqueue_bindings.Stubs(Kqueue_stubs).Kevent.t list -> t
  val to_list : t -> Kqueue_bindings.Stubs(Kqueue_stubs).Kevent.t list

  val fold : f:('a -> Kqueue_bindings.Stubs(Kqueue_stubs).Kevent.t -> 'a) -> init:'a -> t -> 'a
  val iter : f:(Kqueue_bindings.Stubs(Kqueue_stubs).Kevent.t -> unit) -> t -> unit
end

(** [kqueue] can take an optional timeout constructed of seconds and
    nanoseconds. *)
module Timeout : sig
  type t

  val create : sec:int -> nsec:int -> t
end

type t

val create : unit -> t

(** This is a direct mapping to the kqueue call in FreeBSD except that for how the
    size of [changelist] and [eventlist] are affected.  In the call, the [size] of
    [changelist] is used as input, and the [capacity] of [eventlist] is used as
    input.  In output, if the call to [kevent] was successful, the size of
    [eventlist] will be set to the return value of [kevent].  On error, the size
    of [eventlist] is set to 0.  This is to make it impossible to access outside
    those events that were set by the [kqueue] call.  In all cases, the return of
    [kevent] is returned unaltered.

    @param changelist the set of changes to events to listen to

    @param eventlist [Eventlist] to fill in if any events have been triggered

    @param timeout optional timeout for the kqueue call

    @return the value of the underlying [kqueue] call *)
val kevent :
  t ->
  changelist:Eventlist.t ->
  eventlist:Eventlist.t ->
  timeout:Timeout.t option ->
  int

val unsafe_int_of_file_descr : Unix.file_descr -> int
val unsafe_file_descr_of_int : int -> Unix.file_descr
