module C = Ctypes
module Stubs = Kqueue_bindings.Stubs (Kqueue_stubs)

module Action = struct
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

    let to_ushort = function
      | Add      -> Stubs.ev_add
      | Enable   -> Stubs.ev_enable
      | Disable  -> Stubs.ev_disable
      | Dispatch -> Stubs.ev_dispatch
      | Delete   -> Stubs.ev_delete
      | Receipt  -> Stubs.ev_receipt
      | Oneshot  -> Stubs.ev_oneshot
      | Clear    -> Stubs.ev_clear
      | Eof      -> Stubs.ev_eof
      | Error    -> Stubs.ev_error
  end

  type t = Unsigned.UShort.t

  let to_t flags =
    List.fold_left
      (fun acc e -> Unsigned.UShort.logor acc (Flag.to_ushort e))
      Unsigned.UShort.zero
      flags

  let of_t t =
    List.filter
      (fun f ->
        let i = Flag.to_ushort f in
        i = Unsigned.UShort.logand i t)
      Flag.[ Add; Enable; Disable; Dispatch; Delete; Receipt; Oneshot; Clear; Eof; Error ]
end

module Filter = struct
  module Read = struct
    type t = int
  end

  module Write = struct
    type t = int
  end

  module Vnode = struct
    module Flags = Kqueue_flags.Vnode

    type t = {
      descr : int;
      flags : Flags.t;
    }
  end

  module Proc = struct
    module Flags = Kqueue_flags.Proc

    type t = {
      pid : int;
      flags : Flags.t;
    }
  end

  module Signal = struct
    type t = int
  end

  module Timer = struct
    module Unit = Kqueue_flags.Timer

    type t = {
      id : int;
      unit : Unit.t;
      time : int;
    }
  end

  module User = struct
    module Flags = Kqueue_flags.User

    type t = {
      id : int;
      flags : Flags.t;
      data : int;
    }
  end

  type t =
    | Read   of Read.t
    | Write  of Write.t
    | Vnode  of Vnode.t
    | Proc   of Proc.t
    | Signal of Signal.t
    | Timer  of Timer.t
    | User   of User.t

  let set kevent ~ident ~filter ~flags ~fflags ~data ~udata =
    C.setf kevent Stubs.Kevent.ident ident;
    C.setf kevent Stubs.Kevent.filter filter;
    C.setf kevent Stubs.Kevent.flags flags;
    C.setf kevent Stubs.Kevent.fflags fflags;
    C.setf kevent Stubs.Kevent.data data;
    C.setf kevent Stubs.Kevent.udata udata

  let set_kevent kevent action = function
    | Read read     ->
        set
          kevent
          ~ident:(C.Uintptr.of_int read)
          ~filter:Stubs.evfilt_read
          ~flags:action
          ~fflags:Unsigned.UInt.zero
          ~data:C.Intptr.zero
          ~udata:C.Uintptr.zero
    | Write write   ->
        set
          kevent
          ~ident:(C.Uintptr.of_int write)
          ~filter:Stubs.evfilt_write
          ~flags:action
          ~fflags:Unsigned.UInt.zero
          ~data:C.Intptr.zero
          ~udata:C.Uintptr.zero
    | Vnode vnode   ->
        set
          kevent
          ~ident:(C.Uintptr.of_int vnode.Vnode.descr)
          ~filter:Stubs.evfilt_vnode
          ~flags:action
          ~fflags:vnode.Vnode.flags
          ~data:C.Intptr.zero
          ~udata:C.Uintptr.zero
    | Proc proc     ->
        set
          kevent
          ~ident:(C.Uintptr.of_int proc.Proc.pid)
          ~filter:Stubs.evfilt_proc
          ~flags:action
          ~fflags:proc.Proc.flags
          ~data:C.Intptr.zero
          ~udata:C.Uintptr.zero
    | Signal signal ->
        set
          kevent
          ~ident:(C.Uintptr.of_int signal)
          ~filter:Stubs.evfilt_signal
          ~flags:action
          ~fflags:Unsigned.UInt.zero
          ~data:C.Intptr.zero
          ~udata:C.Uintptr.zero
    | Timer timer   ->
        set
          kevent
          ~ident:(C.Uintptr.of_int timer.Timer.id)
          ~filter:Stubs.evfilt_timer
          ~flags:action
          ~fflags:timer.Timer.unit
          ~data:(C.Intptr.of_int timer.Timer.time)
          ~udata:C.Uintptr.zero
    | User user     ->
        set
          kevent
          ~ident:(C.Uintptr.of_int user.User.id)
          ~filter:Stubs.evfilt_user
          ~flags:action
          ~fflags:user.User.flags
          ~data:C.Intptr.zero
          ~udata:(C.Uintptr.of_int user.User.data)

  let to_kevent action filter =
    let kevent = C.make Stubs.Kevent.t in
    set_kevent kevent action filter;
    kevent
end
