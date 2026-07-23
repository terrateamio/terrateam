(** [Sys.sleep] tests: precision and abort under load. *)
module Make (_ : Abb_intf.S) : sig
  val test : Oth.Test.t
end
