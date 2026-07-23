(** Smoke tests: simple file I/O round-trip through the scheduler. *)
module Make (_ : Abb_intf.S) : sig
  val test : Oth.Test.t
end
