module C = Ctypes
module F = Foreign

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
  let flags_to_uint conv flags =
    List.fold_left
      (fun acc f -> Unsigned.UInt.logor acc (conv f))
      Unsigned.UInt.zero
      flags

  module Read = struct
    type t = int
  end

  module Write = struct
    type t = int
  end

  module Vnode = struct
    module Flags = struct
      type f =
        | Delete
        | Write
        | Extend
        | Attrib
        | Link
        | Rename
        | Revoke

      type t = Unsigned.UInt.t

      let f_to_uint = function
        | Delete -> Stubs.note_delete
        | Write  -> Stubs.note_write
        | Extend -> Stubs.note_extend
        | Attrib -> Stubs.note_attrib
        | Link -> Stubs.note_link
        | Rename -> Stubs.note_rename
        | Revoke -> Stubs.note_revoke

      let to_t = flags_to_uint f_to_uint

      let of_t t = failwith "nyi"
    end

    type t = { descr : int
             ; flags : Flags.t
             }
  end

  module Proc = struct
    module Flags = struct
      type f =
        | Exit
        | Fork
        | Exec
        | Track

      type t = Unsigned.UInt.t

      let f_to_uint = function
        | Exit -> Stubs.note_exit
        | Fork -> Stubs.note_fork
        | Exec -> Stubs.note_exec
        | Track -> Stubs.note_track

      let to_t = flags_to_uint f_to_uint

      let of_t t = failwith "nyi"
    end

    type t = { pid : int
             ; flags : Flags.t
             }
  end

  module Signal = struct
    type t = int
  end

  module Timer = struct
    module Unit = struct
      type u =
        | Seconds
        | Mseconds
        | Useconds
        | Nseconds

      type t = Unsigned.UInt.t

      let to_t = function
        | Seconds -> Stubs.note_seconds
        | Mseconds -> Stubs.note_mseconds
        | Useconds -> Stubs.note_useconds
        | Nseconds -> Stubs.note_nseconds

      let of_t t = failwith "nyi"
    end

    type t = { id : int
             ; unit : Unit.t
             ; time : int
             }
  end

  module User = struct
    module Flags = struct
      type f =
        | Nop
        | And
        | Or
        | Copy
        | Ctrlmask
        | Fflagsmask
        | Trigger

      type t = Unsigned.UInt.t

      let f_to_uint = function
        | Nop -> Stubs.note_ffnop
        | And -> Stubs.note_ffand
        | Or -> Stubs.note_ffor
        | Copy -> Stubs.note_ffcopy
        | Ctrlmask -> Stubs.note_ffctrlmask
        | Fflagsmask -> Stubs.note_fflagsmask
        | Trigger -> Stubs.note_trigger

      let to_t = flags_to_uint f_to_uint

      let of_t t = failwith "nyi"
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
end

module Kevent = struct
  type t = Stubs.Kevent.t

  let set t ~ident ~filter ~fflags ~data ~udata =
    C.setf t Stubs.Kevent.ident ident;
    C.setf t Stubs.Kevent.filter filter;
    C.setf t Stubs.Kevent.fflags fflags;
    C.setf t Stubs.Kevent.data data;
    C.setf t Stubs.Kevent.udata udata

  let set_from_filter t = function
    | Filter.Read read ->
      set
        t
        ~ident:(C.Uintptr.of_int read)
        ~filter:Stubs.evfilt_read
        ~fflags:Unsigned.UInt.zero
        ~data:C.Intptr.zero
        ~udata:C.null
    | Filter.Write write ->
      set
        t
        ~ident:(C.Uintptr.of_int write)
        ~filter:Stubs.evfilt_write
        ~fflags:Unsigned.UInt.zero
        ~data:C.Intptr.zero
        ~udata:C.null
    | Filter.Vnode vnode ->
      set
        t
        ~ident:(C.Uintptr.of_int vnode.Filter.Vnode.descr)
        ~filter:Stubs.evfilt_vnode
        ~fflags:vnode.Filter.Vnode.flags
        ~data:C.Intptr.zero
        ~udata:C.null
    | Filter.Proc proc ->
      set
        t
        ~ident:(C.Uintptr.of_int proc.Filter.Proc.pid)
        ~filter:Stubs.evfilt_proc
        ~fflags:proc.Filter.Proc.flags
        ~data:C.Intptr.zero
        ~udata:C.null
    | Filter.Signal signal ->
      set
        t
        ~ident:(C.Uintptr.of_int signal)
        ~filter:Stubs.evfilt_signal
        ~fflags:Unsigned.UInt.zero
        ~data:C.Intptr.zero
        ~udata:C.null
    | Filter.Timer timer ->
      set
        t
        ~ident:(C.Uintptr.of_int timer.Filter.Timer.id)
        ~filter:Stubs.evfilt_timer
        ~fflags:timer.Filter.Timer.unit
        ~data:(C.Intptr.of_int timer.Filter.Timer.time)
        ~udata:C.null
    | Filter.User user ->
      set
        t
        ~ident:(C.Uintptr.of_int user.Filter.User.id)
        ~filter:Stubs.evfilt_user
        ~fflags:Unsigned.UInt.zero
        ~data:C.Intptr.zero
        ~udata:C.null

  let to_filter t = failwith "nyi"
end

module Eventlist = struct
  type t = { kevents : Stubs.Kevent.t C.ptr
           ; count : int
           }

  let create count =
    { kevents = C.allocate_n Stubs.Kevent.t ~count; count}

  let null = { kevents = C.(coerce (ptr void) (ptr Stubs.Kevent.t) null)
             ; count = 0
             }

  let set_from_list t kevents =
    assert (t.count = List.length kevents);
    List.iteri
      (fun idx k ->
        C.((t.kevents +@ idx) <-@ k))
      kevents

  let of_list kevents =
    let count = List.length kevents in
    let t = create count in
    set_from_list t kevents;
    t

  let to_list t = failwith "nyi"

  let fold ~f ~init t =
    let rec f' acc = function
      | n when n < t.count ->
        f' (f acc C.(!@ (t.kevents +@ n))) (n + 1)
      | _ ->
        acc
    in
    f' init 0

  let iter ~f t =
    fold ~f:(fun () -> f) ~init:() t
end

module Timeout = struct
  type t = Stubs.Timespec.t

  let create ~sec ~nsec = failwith "nyi"
end

module Bindings = struct
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

type t = int

let create () = Bindings.kqueue ()

let kevent t ~changelist ~eventlist ~timeout =
  let timeout =
    match timeout with
      | Some _ -> failwith "nyi"
      | None -> C.(from_voidp Stubs.Timespec.t null)
  in
  Bindings.kevent
    t
    changelist.Eventlist.kevents
    changelist.Eventlist.count
    eventlist.Eventlist.kevents
    eventlist.Eventlist.count
    timeout
