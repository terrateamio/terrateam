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

  let ev_add = S.(constant "EV_ADD" ushort)
  let ev_enable = S.(constant "EV_ENABLE" ushort)
  let ev_disable = S.(constant "EV_DISABLE" ushort)
  let ev_dispatch = S.(constant "EV_DISPATCH" ushort)
  let ev_delete = S.(constant "EV_DELETE" ushort)
  let ev_receipt = S.(constant "EV_RECEIPT" ushort)
  let ev_oneshot = S.(constant "EV_ONESHOT" ushort)
  let ev_clear = S.(constant "EV_CLEAR" ushort)
  let ev_eof = S.(constant "EV_EOF" ushort)
  let ev_error = S.(constant "EV_ERROR" ushort)

  let evfilt_read = S.(constant "EVFILT_READ" short)
  let evfilt_write = S.(constant "EVFILT_WRITE" short)
  let evfilt_vnode = S.(constant "EVFILT_VNODE" short)
  let evfilt_proc = S.(constant "EVFILT_PROC" short)
  let evfilt_signal = S.(constant "EVFILT_SIGNAL" short)
  let evfilt_timer = S.(constant "EVFILT_TIMER" short)
  let evfilt_user = S.(constant "EVFILT_USER" short)

  let note_delete = S.(constant "NOTE_DELETE" uint)
  let note_write = S.(constant "NOTE_WRITE" uint)
  let note_extend = S.(constant "NOTE_EXTEND" uint)
  let note_attrib = S.(constant "NOTE_ATTRIB" uint)
  let note_link = S.(constant "NOTE_LINK" uint)
  let note_rename = S.(constant "NOTE_RENAME" uint)
  let note_revoke = S.(constant "NOTE_REVOKE" uint)

  let note_exit = S.(constant "NOTE_EXIT" uint)
  let note_fork = S.(constant "NOTE_FORK" uint)
  let note_exec = S.(constant "NOTE_EXEC" uint)
  let note_track = S.(constant "NOTE_TRACK" uint)

  let note_seconds = S.(constant "NOTE_SECONDS" uint)
  let note_mseconds = S.(constant "NOTE_MSECONDS" uint)
  let note_useconds = S.(constant "NOTE_USECONDS" uint)
  let note_nseconds = S.(constant "NOTE_NSECONDS" uint)

  let note_ffnop = S.(constant "NOTE_FFNOP" uint)
  let note_ffand = S.(constant "NOTE_FFAND" uint)
  let note_ffor = S.(constant "NOTE_FFOR" uint)
  let note_ffcopy = S.(constant "NOTE_FFCOPY" uint)
  let note_ffctrlmask = S.(constant "NOTE_FFCTRLMASK" uint)
  let note_fflagsmask = S.(constant "NOTE_FFLAGSMASK" uint)

  let note_trigger = S.(constant "NOTE_TRIGGER" uint)
end
