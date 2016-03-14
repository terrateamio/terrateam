module Stubs = Kqueue_bindings.Stubs(Kqueue_stubs)

type uint = Unsigned.UInt.t

let flags_to_uint conv flags =
  List.fold_left
    (fun acc f -> Unsigned.UInt.logor acc (conv f))
    Unsigned.UInt.zero
    flags

let uint_to_flags conv uint flags =
  List.filter
    (fun f ->
      let i = conv f in
      i = Unsigned.UInt.logand i uint)
    flags

module Vnode = struct
  type f =
    | Delete
    | Write
    | Extend
    | Attrib
    | Link
    | Rename
    | Revoke

  type t = uint

  let f_to_uint = function
    | Delete -> Stubs.note_delete
    | Write  -> Stubs.note_write
    | Extend -> Stubs.note_extend
    | Attrib -> Stubs.note_attrib
    | Link -> Stubs.note_link
    | Rename -> Stubs.note_rename
    | Revoke -> Stubs.note_revoke

  let to_t = flags_to_uint f_to_uint

  let of_t t =
    uint_to_flags
      f_to_uint
      t
      [Delete; Write; Extend; Attrib; Link; Rename; Revoke]
end

module Proc = struct
  type f =
    | Exit
    | Fork
    | Exec
    | Track

  type t = uint

  let f_to_uint = function
    | Exit -> Stubs.note_exit
    | Fork -> Stubs.note_fork
    | Exec -> Stubs.note_exec
    | Track -> Stubs.note_track

  let to_t = flags_to_uint f_to_uint

  let of_t t =
    uint_to_flags
      f_to_uint
      t
      [Exit; Fork; Exec; Track]
end

module Timer = struct
  type u =
    | Seconds
    | Mseconds
    | Useconds
    | Nseconds

  type t = uint

  let to_t = function
    | Seconds -> Stubs.note_seconds
    | Mseconds -> Stubs.note_mseconds
    | Useconds -> Stubs.note_useconds
    | Nseconds -> Stubs.note_nseconds

  let of_t = function
    | u when u = Stubs.note_seconds -> Seconds
    | u when u = Stubs.note_mseconds -> Mseconds
    | u when u = Stubs.note_useconds -> Useconds
    | u when u = Stubs.note_nseconds -> Nseconds
end

module User = struct
  type f =
    | Nop
    | And
    | Or
    | Copy
    | Ctrlmask
    | Fflagsmask
    | Trigger

  type t = uint

  let f_to_uint = function
    | Nop -> Stubs.note_ffnop
    | And -> Stubs.note_ffand
    | Or -> Stubs.note_ffor
    | Copy -> Stubs.note_ffcopy
    | Ctrlmask -> Stubs.note_ffctrlmask
    | Fflagsmask -> Stubs.note_fflagsmask
    | Trigger -> Stubs.note_trigger

  let to_t = flags_to_uint f_to_uint

  let of_t t =
    uint_to_flags
      f_to_uint
      t
      [Nop; And; Or; Copy; Ctrlmask; Fflagsmask; Trigger]
end
