(* Implementation for reversible operations. *)

module Monad = struct
  type 'a t = 'a

  let ( >>= ) v f = f v
  let return = CCFun.id
  let protect ~f ~finally = CCFun.finally ~f ~h:finally
end

(* Functor application, see revops_fn.ml *)
include Revops_fn.Make (Monad)
