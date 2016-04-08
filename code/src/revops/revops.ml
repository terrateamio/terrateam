(* Implementation for reversible operations. *)

open Core.Std

module Monad = struct
  type 'a t = 'a
  let ( >>= ) v f = f v
  let return = Fn.id
  let protect = protect
end

(* Functor application, see revops_fn.ml *)
include Revops_fn.Make(Monad)
