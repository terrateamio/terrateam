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
  end

  type t

  let to_t flags = failwith "nyi"
  let of_t t = failwith "nyi"
end

module Filters = struct
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
  type t

  let of_filter filters = failwith "nyi"

  let to_filter t = failwith "nyi"

  let of_kevent_unsafe kevent = failwith "nyi"

  let to_kevent_unsafe t = failwith "nyi"
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

  module Stubs = Kqueue_bindings.Stubs(Kqueue_stubs)

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
