(** This schedule is based on kqueue.  It has been tested on FreeBSD and through
   the use of [libkqueue] it can be used on Linux.  Other BSDs have not been
   tested.*)
include Abb_intf.S with type Native.t = Unix.file_descr and type Process.Pid.native = int
