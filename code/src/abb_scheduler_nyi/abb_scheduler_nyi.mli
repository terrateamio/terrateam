(** This scheduler provides no functionality other than a base to develop new
   schedulers from. *)
include Abb_intf.S with type Native.t = unit and type Process.Pid.native = unit
