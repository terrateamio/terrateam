module Flags : sig
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

module Filters : sig
  module Read : sig
    type t = int
  end

  module Write : sig
    type t = int
  end

  module Vnode : sig
    module Flags : sig
      type t =
        | Delete
        | Write
        | Extend
        | Attrib
        | Link
        | Rename
        | Revoke
    end

    type t = { desc : int
             ; flags : Flags.t list
             }
  end

  module Proc : sig
    module Flags : sig
      type t =
        | Exit
        | Fork
        | Exec
        | Track
    end

    type t = { pid : int
             ; flags : Flags.t list
             }
  end

  module Signal : sig
    type t = int
  end

  module Timer : sig
    module Unit : sig
      type t =
        | Seconds
        | Mseconds
        | Useconds
        | Nseconds
    end

    type t = { id : int
             ; unit : Unit.t
             ; time : int
             }
  end

  module User : sig
    module Flags : sig
      type t =
        | Nop
        | And
        | Or
        | Copy
        | Ctrlmask
        | Fflagsmask
        | Trigger
    end

    type t = { id : int
             ; flags : Flags.t list
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
  type t

  val of_filter : Filters.t -> t
  val to_filter : t -> Filters.t

  val of_kevent_unsafe : Kqueue_bindings.Stubs(Kqueue_stubs).Kevent.t -> t
  val to_kevent_unsafe : t -> Kqueue_bindings.Stubs(Kqueue_stubs).Kevent.t
end

module Eventlist : sig
  type t

  val create : int -> t
  val null : t

  val of_list : Kevent.t list -> t
  val to_list : t -> Kevent.t list

  val fold : f:(Kevent.t -> 'a -> 'a) -> init:'a -> t -> 'a
end

module Timeout : sig
  type t

  val create : sec:int -> nsec:int -> t
end

type t

val create : unit -> t

val kevent :
  t ->
  changelist:Eventlist.t ->
  eventlist:Eventlist.t ->
  timeout:Timeout.t option ->
  int
