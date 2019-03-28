(** Types for events triggered by [kqueue] *)
exception Unknown_filter of int

module Read : sig
  type t = { descr : int
           ; len : int
           }
end

module Write : sig
  type t = { descr : int
           ; len : int
           }
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
      (* libkqueue does not support Revoke *)
      (* | Revoke *)

    type t
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
    val of_t : t -> f list
  end

  type t = { pid : int
           ; flags : Flags.t
           }
end

module Signal : sig
  type t = { signal : int
           ; count : int
           }
end

module Timer : sig
  type t = { id : int
           ; count : int
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
      | Uflags of int

    type t
    val of_t : t -> f list
  end

  type t = { id : int
           ; flags : Flags.t
           ; data : int
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

(** Turn a [struct kqueue] into an [Event] *)
val of_kevent : Kqueue_bindings.Stubs(Kqueue_stubs).Kevent.t -> t
