module State = struct
  type ('a, 's) t = 's -> ('a * 's) Abb.Future.t
end

type 'a policy = { ops : 'a list }
type ('a, 'b) t = ('a, 'b policy) State.t

let append op p = Abb.Future.return ((), { ops = op :: p.ops })
let return v p = Abb.Future.return (v, p)

let exec fut p =
  let open Abb.Future.Infix_monad in
  fut >>= fun v -> return v p

let bind : ('a, 'b) t -> ('a -> ('c, 'b) t) -> ('c, 'b) t =
 fun a f p ->
  let open Abb.Future.Infix_monad in
  a p >>= fun (v, p') -> f v p'

let run f =
  let open Abb.Future.Infix_monad in
  bind (return ()) f { ops = [] }
  >>= function
  | Ok r, p -> Abb.Future.return (Ok (r, CCList.rev p.ops))
  | Error err, p -> Abb.Future.return (Error (`Error (err, CCList.rev p.ops)))

module Syntax = struct
  let ( let* ) = bind

  let ( let+ ) a f =
    let* res = a in
    match res with
    | Ok v -> f v
    | Error _ as err -> return err
end
