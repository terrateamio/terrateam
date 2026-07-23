(** [Task.id] / [Task.run] / [Task.name] tests. Covers id propagation, name propagation, isolation
    between sibling and nested tasks, behaviour under sleep / promise resumption, and abort /
    exception semantics. *)
module Make (_ : Abb_intf.S) : sig
  val test : Oth.Test.t
end
