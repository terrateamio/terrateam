(*
 * Interface for reversible operations.
 *)

module Make : functor (Monad : Revops_intf.MONAD) -> Revops_intf.S with type 'a M.t = 'a Monad.t
