module Stubs = Kqueue_bindings.Stubs(Kqueue_stubs)

module Flags = struct
  module Flag = struct
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

    let to_nativeint = function
      | Add -> Stubs.ev_add
      | Enable -> Stubs.ev_enable
      | Disable -> Stubs.ev_disable
      | Dispatch -> Stubs.ev_dispatch
      | Delete -> Stubs.ev_delete
      | Receipt -> Stubs.ev_receipt
      | Oneshot -> Stubs.ev_oneshot
      | Clear -> Stubs.ev_clear
      | Eof -> Stubs.ev_eof
      | Error -> Stubs.ev_error
  end

  type t = nativeint

  let to_t flags =
    List.fold_left
      (fun acc e -> Nativeint.logor acc (Flag.to_nativeint e))
      Nativeint.zero
      flags

  let of_t t = failwith "nyi"
end

module Filter = struct
  module Read = struct
    type t = int
  end

  module Write = struct
    type t = int
  end

  module Vnode = struct
    module Flags = struct
      type t =
        | Delete
        | Write
        | Extend
        | Attrib
        | Link
        | Rename
        | Revoke

      let to_nativeint = function
        | Delete -> Stubs.note_delete
        | Write  -> Stubs.note_write
        | Extend -> Stubs.note_extend
        | Attrib -> Stubs.note_attrib
        | Link -> Stubs.note_link
        | Rename -> Stubs.note_rename
        | Revoke -> Stubs.note_revoke
    end

    type t = { desc : int
             ; flags : Flags.t list
             }
  end

  module Proc = struct
    module Flags = struct
      type t =
        | Exit
        | Fork
        | Exec
        | Track

      let to_nativeint = function
        | Exit -> Stubs.note_exit
        | Fork -> Stubs.note_fork
        | Exec -> Stubs.note_exec
        | Track -> Stubs.note_track
    end

    type t = { pid : int
             ; flags : Flags.t list
             }
  end

  module Signal = struct
    type t = int
  end

  module Timer = struct
    module Unit = struct
      type t =
        | Seconds
        | Mseconds
        | Useconds
        | Nseconds

      let to_nativeint = function
        | Seconds -> Stubs.note_seconds
        | Mseconds -> Stubs.note_mseconds
        | Useconds -> Stubs.note_useconds
        | Nseconds -> Stubs.note_nseconds
    end

    type t = { id : int
             ; unit : Unit.t
             ; time : int
             }
  end

  module User = struct
    module Flags = struct
      type t =
        | Nop
        | And
        | Or
        | Copy
        | Ctrlmask
        | Fflagsmask
        | Trigger

      let to_nativeint = function
        | Nop -> Stubs.note_ffnop
        | And -> Stubs.note_ffand
        | Or -> Stubs.note_ffor
        | Copy -> Stubs.note_ffcopy
        | Ctrlmask -> Stubs.note_ffctrlmask
        | Fflagsmask -> Stubs.note_fflagsmask
        | Trigger -> Stubs.note_trigger
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

module Kevent = struct
  type t = Stubs.Kevent.t

  let of_filter = function
    | Filter.Read _ -> failwith "nyi"
    | Filter.Write _ -> failwith "nyi"
    | Filter.Vnode _ -> failwith "nyi"
    | Filter.Proc _ -> failwith "nyi"
    | Filter.Signal _ -> failwith "nyi"
    | Filter.Timer _ -> failwith "nyi"
    | Filter.User _ -> failwith "nyi"

  let to_filter t = failwith "nyi"

  let of_kevent_unsafe kevent = kevent

  let to_kevent_unsafe t = t
end

module Eventlist = struct
  type t

  let create size = failwith "nyi"

  let null = failwith "nyi"

  let of_list kevents = failwith "nyi"

  let to_list t = failwith "nyi"

  let fold ~f ~init t = failwith "nyi"
end

module Timeout = struct
  type t

  let create ~sec ~nsec = failwith "nyi"
end

module Binding = struct
  module C = Ctypes
  module F = Foreign

  let kqueue =
    F.foreign
      "kqueue"
      C.(void @-> returning int)

  let kevent =
    F.foreign
      "kevent"
      C.(int @->
         ptr Stubs.Kevent.t @->
         int @->
         ptr Stubs.Kevent.t @->
         int @->
         ptr Stubs.Timespec.t @->
         returning int)
end

type t

let create () = failwith "nyi"

let kevent t ~changelist ~eventlist ~timeout = failwith "nyi"
