(** Subprocess spawn / wait tests via [Abb_intf.Process]. *)
module Make (_ : Abb_intf.S) : sig
  val test : Oth.Test.t
end
