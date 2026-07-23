type output_err =
  [ Abb_intf.Errors.spawn
  | Abb_intf.Errors.write
  | Abb_intf.Errors.read
  | Abb_intf.Errors.close
  ]
[@@deriving show]

type check_output_err =
  [ output_err
  | `Run_error of Abb_intf.Process.t * string * string * Abb_intf.Process.Exit_code.t
  ]
[@@deriving show]

val args : ?env:(string * string) list -> string -> string list -> Abb_intf.Process.t

module Make (Abb : Abb_intf.S with type Native.t = Unix.file_descr) : sig
  (** Run a process, writing in an optional input string, and collecting its stdout and stderr, and
      return code *)
  val output :
    ?input:string ->
    Abb_intf.Process.t ->
    (string * string * Abb_intf.Process.Exit_code.t, [> output_err ]) result Abb.Future.t

  (** Run a process with optional input, and collecting stdout and stderr, and if it completes with
      a [0] exist code it is considered a success. *)
  val check_output :
    ?input:string ->
    Abb_intf.Process.t ->
    (string * string, [> check_output_err ]) result Abb.Future.t
end
