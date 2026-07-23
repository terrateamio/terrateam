(** Socket round-trip test: server accepts and echoes; client sends and verifies. *)
module Make (_ : Abb_intf.S) : sig
  val test : Oth.Test.t
end
