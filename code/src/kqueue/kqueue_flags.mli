type uint = Unsigned.UInt.t

module Vnode : sig
  type f =
    | Delete
    | Write
    | Extend
    | Attrib
    | Link
    | Rename
    | Revoke

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
    | Mseconds
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

  type t = uint

  val of_t : t -> f list
  val to_t : f list -> t
end
