open Core.Std

module Make = functor (Revops : Revops_intf.S) -> struct
  module R = Revops

  module M = Revops.M

  module KeyOprev = struct
    type 'a t = 'a Univ_map.Key.t * 'a Revops.Oprev.t
  end

  let noop =
    Revops.Oprev.make
      (Fn.const (M.return Univ_map.empty))
      (Fn.const (M.return ()))

  let extend first (key, oprev) =
    let introduce map value = M.return (Univ_map.set map key value) in
    let eliminate_second map = M.return (Univ_map.find_exn map key) in
    Revops.compose
      ~introduce
      ~eliminate_first:M.return
      ~eliminate_second
      ~first
      ~second:oprev

  let ( +> ) = extend

  let key name = Univ_map.Key.create ~name sexp_of_opaque
end
