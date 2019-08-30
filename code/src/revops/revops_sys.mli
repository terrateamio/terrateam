(* Interface for basic revops for system operations. *)

(*
 * A revop for creating a temporary file and cleaning up afterward.
 *)
val temp_file : ?prefix:string -> ?suffix:string -> unit -> string Revops.Oprev.t
