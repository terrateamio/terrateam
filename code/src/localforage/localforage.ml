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

let global : unit -> store Js.t = fun _ -> Js.Unsafe.global##.localforage

module Typed = struct
  type 'a t = {
    store : store Js.t;
    encode : 'a -> string;
    decode : string -> 'a option;
  }

  let create ~encode ~decode name =
    let store =
      (global ())##createInstance
        (object%js
           val name = Js.string name
        end)
    in
    { store; encode; decode }

  let destroy t = Abb_fut_js.unsafe_of_promise t.store##dropInstance

  let set_item t ~key v =
    Abb_fut_js.unsafe_of_promise
      (t.store##setItem (Js.string key) (Js.Unsafe.inject (Js.string (t.encode v))))

  let get_item t key =
    let open Abb_fut_js.Infix_monad in
    Abb_fut_js.unsafe_of_promise (t.store##getItem (Js.string key))
    >>| fun s ->
    CCOpt.flat_map CCFun.(Js.Unsafe.coerce %> Js.to_string %> t.decode) (Js.Opt.to_option s)

  let remove_item t key = Abb_fut_js.unsafe_of_promise (t.store##removeItem (Js.string key))

  let clear t = Abb_fut_js.unsafe_of_promise t.store##clear

  let length t = Abb_fut_js.unsafe_of_promise t.store##length

  let keys t =
    let open Abb_fut_js.Infix_monad in
    Abb_fut_js.unsafe_of_promise t.store##keys
    >>| fun keys -> keys |> Js.to_array |> Array.to_list |> List.map Js.to_string
end

include Typed

type t = string Typed.t

let create name = Typed.create ~encode:CCFun.id ~decode:CCOpt.return name
