type output_err =
  [ Abb_intf.Errors.spawn
  | Abb_intf.Errors.write
  | Abb_intf.Errors.read
  | Abb_intf.Errors.close
  ]

module Make (Abb : Abb_intf.S with type Native.t = Unix.file_descr) : sig
  (** Run a process, writing in an optional input string, and collecting its stdout and stderr, and return code *)
  val output :
    ?input:string ->
    Abb_intf.Process.t ->
    (string * string * Abb_intf.Process.Exit_code.t, [> output_err ]) result Abb.Future.t
end
