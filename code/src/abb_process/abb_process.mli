type output_err =
  [ Abb_intf.Errors.spawn
  | Abb_intf.Errors.write
  | Abb_intf.Errors.read
  | Abb_intf.Errors.close
  ]

type check_output_err =
  [ output_err
  | `Run_error of Abb_intf.Process.t * string * string * Abb_intf.Process.Exit_code.t
  ]

val pp_output_err : Format.formatter -> output_err -> unit

val show_output_err : output_err -> string

val pp_check_output_err : Format.formatter -> check_output_err -> unit

val show_check_output_err : check_output_err -> string

val args : string -> string list -> Abb_intf.Process.t

module Make (Abb : Abb_intf.S with type Native.t = Unix.file_descr) : sig
  (** Run a process, writing in an optional input string, and collecting its stdout and stderr, and return code *)
  val output :
    ?input:string ->
    Abb_intf.Process.t ->
    (string * string * Abb_intf.Process.Exit_code.t, [> output_err ]) result Abb.Future.t

  (** Run a process with optional input, and collecting stdout and stderr, and
      if it completes with a [0] exist code it is considered a success. *)
  val check_output :
    ?input:string ->
    Abb_intf.Process.t ->
    (string * string, [> check_output_err ]) result Abb.Future.t
end
