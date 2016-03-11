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

  let ev_add = S.(constant "EV_ADD" int)
  let ev_enable = S.(constant "EV_ENABLE" int)
  let ev_disable = S.(constant "EV_DISABLE" int)
  let ev_dispatch = S.(constant "EV_DISPATCH" int)
  let ev_delete = S.(constant "EV_DELETE" int)
  let ev_receipt = S.(constant "EV_RECEIPT" int)
  let ev_oneshot = S.(constant "EV_ONESHOT" int)
  let ev_clear = S.(constant "EV_CLEAR" int)
  let ev_eof = S.(constant "EV_EOF" int)
  let ev_error = S.(constant "EV_ERROR" int)

  let evfilt_read = S.(constant "EVFILT_READ" int)
  let evfilt_write = S.(constant "EVFILT_WRITE" int)
  let evfilt_vnode = S.(constant "EVFILT_VNODE" int)
  let evfilt_proc = S.(constant "EVFILT_PROC" int)
  let evfilt_signal = S.(constant "EVFILT_SIGNAL" int)
  let evfilt_timer = S.(constant "EVFILT_TIMER" int)
  let evfilt_user = S.(constant "EVFILT_USER" int)

  let note_delete = S.(constant "NOTE_DELETE" int)
  let note_write = S.(constant "NOTE_WRITE" int)
  let note_extend = S.(constant "NOTE_EXTEND" int)
  let note_attrib = S.(constant "NOTE_ATTRIB" int)
  let note_link = S.(constant "NOTE_LINK" int)
  let note_rename = S.(constant "NOTE_RENAME" int)
  let note_revoke = S.(constant "NOTE_REVOKE" int)

  let note_exit = S.(constant "NOTE_EXIT" int)
  let note_fork = S.(constant "NOTE_FORK" int)
  let note_exec = S.(constant "NOTE_EXEC" int)
  let note_track = S.(constant "NOTE_TRACK" int)

  let note_seconds = S.(constant "NOTE_SECONDS" int)
  let note_mseconds = S.(constant "NOTE_MSECONDS" int)
  let note_useconds = S.(constant "NOTE_USECONDS" int)
  let note_nseconds = S.(constant "NOTE_NSECONDS" int)

  let note_ffnop = S.(constant "NOTE_FFNOP" int)
  let note_ffand = S.(constant "NOTE_FFAND" int)
  let note_ffor = S.(constant "NOTE_FFOR" int)
  let note_ffcopy = S.(constant "NOTE_FFCOPY" int)
  let note_ffctrlmask = S.(constant "NOTE_FFCTRLMASK" int)
  let note_fflagsmask = S.(constant "NOTE_FFLAGSMASK" int)

  let note_trigger = S.(constant "NOTE_TRIGGER" int)
end
