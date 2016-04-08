(* Reversible operations using Univ_map as its state type. *)

module Make : functor (Revops : Revops_intf.S) ->
    (Revops_univ_intf.S with type 'a R.Oprev.t = 'a Revops.Oprev.t)
