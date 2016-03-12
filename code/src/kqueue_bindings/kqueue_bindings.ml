module C = Ctypes
module F = Foreign

module Stubs = functor (S : Cstubs_structs.TYPE) -> struct
  module Kevent = struct
    type kevent
    type t = kevent C.structure
    let t : t S.typ = S.structure "kevent"
    let ident = S.(field t "ident" uintptr_t)
    let filter = S.(field t "filter" short)
    let flags = S.(field t "flags" ushort)
    let fflags = S.(field t "fflags" uint)
    let data = S.(field t "data" intptr_t)
    let udata = S.(field t "udata" (ptr void))
    let () = S.seal t
  end

  module Timespec = struct
    type timespec
    type t = timespec C.structure
    let t : t S.typ = S.structure "timespec"
    let tv_sec = S.(field t "tv_sec" (lift_typ PosixTypes.time_t))
    let tv_nsec = S.(field t "tv_nsec" long)
    let () = S.seal t
  end

  let ev_add = S.(constant "EV_ADD" nativeint)
  let ev_enable = S.(constant "EV_ENABLE" nativeint)
  let ev_disable = S.(constant "EV_DISABLE" nativeint)
  let ev_dispatch = S.(constant "EV_DISPATCH" nativeint)
  let ev_delete = S.(constant "EV_DELETE" nativeint)
  let ev_receipt = S.(constant "EV_RECEIPT" nativeint)
  let ev_oneshot = S.(constant "EV_ONESHOT" nativeint)
  let ev_clear = S.(constant "EV_CLEAR" nativeint)
  let ev_eof = S.(constant "EV_EOF" nativeint)
  let ev_error = S.(constant "EV_ERROR" nativeint)

  let evfilt_read = S.(constant "EVFILT_READ" nativeint)
  let evfilt_write = S.(constant "EVFILT_WRITE" nativeint)
  let evfilt_vnode = S.(constant "EVFILT_VNODE" nativeint)
  let evfilt_proc = S.(constant "EVFILT_PROC" nativeint)
  let evfilt_signal = S.(constant "EVFILT_SIGNAL" nativeint)
  let evfilt_timer = S.(constant "EVFILT_TIMER" nativeint)
  let evfilt_user = S.(constant "EVFILT_USER" nativeint)

  let note_delete = S.(constant "NOTE_DELETE" nativeint)
  let note_write = S.(constant "NOTE_WRITE" nativeint)
  let note_extend = S.(constant "NOTE_EXTEND" nativeint)
  let note_attrib = S.(constant "NOTE_ATTRIB" nativeint)
  let note_link = S.(constant "NOTE_LINK" nativeint)
  let note_rename = S.(constant "NOTE_RENAME" nativeint)
  let note_revoke = S.(constant "NOTE_REVOKE" nativeint)

  let note_exit = S.(constant "NOTE_EXIT" nativeint)
  let note_fork = S.(constant "NOTE_FORK" nativeint)
  let note_exec = S.(constant "NOTE_EXEC" nativeint)
  let note_track = S.(constant "NOTE_TRACK" nativeint)

  let note_seconds = S.(constant "NOTE_SECONDS" nativeint)
  let note_mseconds = S.(constant "NOTE_MSECONDS" nativeint)
  let note_useconds = S.(constant "NOTE_USECONDS" nativeint)
  let note_nseconds = S.(constant "NOTE_NSECONDS" nativeint)

  let note_ffnop = S.(constant "NOTE_FFNOP" nativeint)
  let note_ffand = S.(constant "NOTE_FFAND" nativeint)
  let note_ffor = S.(constant "NOTE_FFOR" nativeint)
  let note_ffcopy = S.(constant "NOTE_FFCOPY" nativeint)
  let note_ffctrlmask = S.(constant "NOTE_FFCTRLMASK" nativeint)
  let note_fflagsmask = S.(constant "NOTE_FFLAGSMASK" nativeint)

  let note_trigger = S.(constant "NOTE_TRIGGER" nativeint)
end
