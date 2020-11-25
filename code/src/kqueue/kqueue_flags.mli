(** Flags are shared between the {!Kqueue_change} and {!Kqueue_event} modules,
    however the desired signature is slightly different in each context.  This
    module implements the commonalities and the other modules restrict the
    interface *)
type uint = Unsigned.UInt.t

module Vnode : sig
  type f =
    | Delete
    | Write
    | Extend
    | Attrib
    | Link
    | Rename

  (* libkqueue does not support Revoke *)
  (* | Revoke *)

  type t = uint

  val of_t : t -> f list

  val to_t : f list -> t
end

module Proc : sig
  type f =
    | Exit
    | Fork
    | Exec
    | Track

  type t = uint

  val of_t : t -> f list

  val to_t : f list -> t
end

module Timer : sig
  type u =
    | Seconds
    (* libkqueue does not support Mseconds *)
    (* | Mseconds *)
    | Useconds
    | Nseconds

  type t = uint

  val of_t : t -> u

  val to_t : u -> t
end

module User : sig
  type f =
    | Nop
    | And
    | Or
    | Copy
    | Ctrlmask
    | Fflagsmask
    | Trigger
    | Uflags     of int

  type t = uint

  val of_t : t -> f list

  val to_t : f list -> t
end
