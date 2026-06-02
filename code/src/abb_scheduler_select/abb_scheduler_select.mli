(** A scheduler based on [select]. It is fairly limited. As of this writing, Ocaml is compiled to
    only support 1024 concurrent file descriptors. This is meant to be the most portable solution
    but not for any high-performance application. For real workloads use [Abb_scheduler_luv]. *)
include Abb_intf.S with type Native.t = Unix.file_descr and type Process.Pid.native = int
