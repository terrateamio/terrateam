include Abb_fut.Make (struct
  type t = unit
end)

let dummy_state = Abb_fut.State.create ()

let run t = ignore (run_with_state t dummy_state)

class type ['a] promise =
  object
    method then_ :
      ('a -> 'b) Js_of_ocaml.Js.callback -> 'b promise Js_of_ocaml.Js.t Js_of_ocaml.Js.meth

    method catch :
      (Js_of_ocaml.Js.error Js_of_ocaml.Js.t -> 'b) ->
      'b promise Js_of_ocaml.Js.t Js_of_ocaml.Js.meth
  end

let unsafe_of_promise : 'a promise Js_of_ocaml.Js.t -> 'b t =
 fun v ->
  let module Js = Js_of_ocaml.Js in
  let p = Promise.create () in
  ignore ((Js.Unsafe.coerce v)##then_ (Js.wrap_callback (fun v -> run (Promise.set p v))));
  ignore
    ((Js.Unsafe.coerce v)##catch
       (Js.wrap_callback (fun err -> run (Promise.set_exn p (Js.Error err, None)))));
  Promise.future p

let unsafe_to_promise : 'a t -> 'a promise Js_of_ocaml.Js.t =
 fun t ->
  let module Js = Js_of_ocaml.Js in
  let promise_ctor :
      ((('a -> unit) -> (Js.Unsafe.any -> unit) -> unit) Js.callback -> 'a promise Js.t) Js.constr =
    Js.Unsafe.global##._Promise
  in
  let promise =
    new%js promise_ctor
      (Js.wrap_callback (fun succ reject ->
           run
             (let open Infix_monad in
             await_map
               (function
                 | `Det r                 -> succ r
                 | `Aborted               -> reject (Js.Unsafe.inject (Js.string "Aborted"))
                 | `Exn (Js.Error err, _) -> reject (Js.Unsafe.inject err)
                 | `Exn (exn, _)          -> reject (Js.Unsafe.inject exn))
               t)))
  in
  promise
