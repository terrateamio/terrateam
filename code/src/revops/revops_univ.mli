(* Reversible operations using Univ_map as its state type. *)
include Revops_univ_intf.S with type 'a R.Oprev.t = 'a Revops.Oprev.t
