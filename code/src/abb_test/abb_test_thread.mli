(** [Thread.run] tests: dispatching work onto the scheduler's thread/domain pool. *)
module Make (_ : Abb_intf.S) : sig
  val test : Oth.Test.t
end
