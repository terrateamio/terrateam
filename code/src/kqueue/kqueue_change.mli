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

  val set_kevent : Kqueue_bindings.Stubs(Kqueue_stubs).Kevent.t -> Action.t -> t -> unit
  val to_kevent : Action.t -> t -> Kqueue_bindings.Stubs(Kqueue_stubs).Kevent.t
end
