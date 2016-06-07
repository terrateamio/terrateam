module C = Ctypes

exception Unknown_filter of int

module Stubs = Kqueue_bindings.Stubs(Kqueue_stubs)

module Read = struct
  type t = { descr : int
           ; len : int
           }
end

module Write = struct
  type t = { descr : int
           ; len : int
           }
end

module Vnode = struct
  module Flags = Kqueue_flags.Vnode

  type t = { descr : int
           ; flags : Flags.t
           }
end

module Proc = struct
  module Flags = Kqueue_flags.Proc

  type t = { pid : int
           ; flags : Flags.t
           }
end

module Signal = struct
  type t = { signal : int
           ; count : int
           }
end

module Timer = struct
  type t = { id : int
           ; count : int
           }
end

module User = struct
  module Flags = Kqueue_flags.User

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

let read_to_filter t =
  let descr = C.(Uintptr.to_int (getf t Stubs.Kevent.ident)) in
  let len = C.(Intptr.to_int (getf t Stubs.Kevent.data)) in
  Read Read.({descr; len})

let write_to_filter t =
  let descr = C.(Uintptr.to_int (getf t Stubs.Kevent.ident)) in
  let len = C.(Intptr.to_int (getf t Stubs.Kevent.data)) in
  Write Write.({descr; len})

let vnode_to_filter t =
  let descr = C.(Uintptr.to_int (getf t Stubs.Kevent.ident)) in
  let flags = C.(getf t Stubs.Kevent.fflags) in
  Vnode Vnode.({descr; flags})

let proc_to_filter t =
  let pid = C.(Uintptr.to_int (getf t Stubs.Kevent.ident)) in
  let flags = C.(getf t Stubs.Kevent.fflags) in
  Proc Proc.({pid; flags})

let signal_to_filter t =
  let signal = C.(Uintptr.to_int (getf t Stubs.Kevent.ident)) in
  let count = C.(Intptr.to_int (getf t Stubs.Kevent.data)) in
  Signal Signal.({signal; count})

let timer_to_filter t =
  let id = C.(Uintptr.to_int (getf t Stubs.Kevent.ident)) in
  let count = C.(Intptr.to_int (getf t Stubs.Kevent.data)) in
  Timer Timer.({id; count})

let user_to_filter t =
  let id = C.(Uintptr.to_int (getf t Stubs.Kevent.ident)) in
  let flags = C.(getf t Stubs.Kevent.fflags) in
  let data = C.(Uintptr.to_int (getf t Stubs.Kevent.udata)) in
  User User.({id; flags; data})

let of_kevent t =
  match C.getf t Stubs.Kevent.filter with
    | filter when filter = Stubs.evfilt_read -> read_to_filter t
    | filter when filter = Stubs.evfilt_write -> write_to_filter t
    | filter when filter = Stubs.evfilt_vnode -> vnode_to_filter t
    | filter when filter = Stubs.evfilt_proc -> proc_to_filter t
    | filter when filter = Stubs.evfilt_signal -> signal_to_filter t
    | filter when filter = Stubs.evfilt_timer -> timer_to_filter t
    | filter when filter = Stubs.evfilt_user -> user_to_filter t
    | filter -> raise (Unknown_filter filter)
