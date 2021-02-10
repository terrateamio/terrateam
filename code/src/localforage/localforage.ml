module Js = Js_of_ocaml.Js

class type create_options =
  object
    method name : Js.js_string Js.t Js.readonly_prop
  end

class type store =
  object
    method createInstance : create_options Js.t -> store Js.t Js.meth

    method dropInstance : unit Abb_fut_js.promise Js.t Js.meth

    method setItem : Js.js_string Js.t -> Js.Unsafe.any -> unit Abb_fut_js.promise Js.t Js.meth

    method getItem : Js.js_string Js.t -> Js.Unsafe.any Js.opt Abb_fut_js.promise Js.t Js.meth

    method removeItem : Js.js_string Js.t -> unit Abb_fut_js.promise Js.t Js.meth

    method clear : unit Abb_fut_js.promise Js.t Js.meth

    method length : int Abb_fut_js.promise Js.t Js.meth

    method keys : Js.js_string Js.js_array Js.t Abb_fut_js.promise Js.t Js.meth
  end

type t = store Js.t

let global : unit -> t = fun _ -> Js.Unsafe.global##.localforage

let create name =
  (global ())##createInstance
    (object%js
       val name = Js.string name
    end)

let destroy t = Abb_fut_js.unsafe_of_promise t##dropInstance

let set_item t ~key value = Abb_fut_js.unsafe_of_promise (t##setItem (Js.string key) value)

let get_item t key =
  let open Abb_fut_js.Infix_monad in
  Abb_fut_js.unsafe_of_promise (t##getItem (Js.string key)) >>| Js.Opt.to_option

let remove_item t key = Abb_fut_js.unsafe_of_promise (t##removeItem (Js.string key))

let clear t = Abb_fut_js.unsafe_of_promise t##clear

let length t = Abb_fut_js.unsafe_of_promise t##length

let keys t =
  let open Abb_fut_js.Infix_monad in
  Abb_fut_js.unsafe_of_promise t##keys
  >>| fun keys -> keys |> Js.to_array |> Array.to_list |> List.map Js.to_string
