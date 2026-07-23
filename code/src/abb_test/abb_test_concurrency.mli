(** Concurrency tests: applicative composition runs both sides in parallel. *)
module Make (_ : Abb_intf.S) : sig
  val test : Oth.Test.t
end
