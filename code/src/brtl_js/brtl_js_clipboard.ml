module Js = Js_of_ocaml.Js

module Blob = struct
  module J = struct
    class type t =
      object
        method text : Js.js_string Js.t Abb_js.Future.promise Js.t Js.meth
      end

    class type property_bag =
      object
        method type_ : Js.js_string Js.t Js.readonly_prop
      end

    let constr : (Js.js_string Js.t Js.js_array Js.t -> property_bag Js.t -> t Js.t) Js.constr =
      Js.Unsafe.global##._Blob
  end

  type t = J.t Js.t

  let create ~typ parts =
    let property_bag =
      object%js
        val type_ = Js.string typ
      end
    in
    new%js J.constr (parts |> CCList.map Js.string |> CCArray.of_list |> Js.array) property_bag

  let text t =
    let open Abb_js.Future.Infix_monad in
    Abb_js.Future.unsafe_of_promise t##text >>| Js.to_string
end

module Clipboard_item = struct
  module J = struct
    class type t =
      object
        method types : Js.js_string Js.t Js.js_array Js.t Js.readonly_prop
        method getType : Js.js_string Js.t -> Blob.t Abb_js.Future.promise Js.t Js.meth
      end

    let constr : ('a -> t Js.t) Js.constr = Js.Unsafe.global##._ClipboardItem
  end

  type t = J.t Js.t

  let create typs =
    new%js J.constr
      (Js.Unsafe.obj (CCArray.of_list (CCList.map (fun (n, v) -> (n, Js.Unsafe.inject v)) typs)))

  let types t = t##.types |> Js.to_array |> CCArray.to_list |> CCList.map Js.to_string
  let get_type t s = Abb_js.Future.unsafe_of_promise (t##getType (Js.string s))
end

module J = struct
  class type t =
    object
      method read : Clipboard_item.t Js.js_array Js.t Abb_js.Future.promise Js.t Js.meth
      method readText : Js.js_string Js.t Abb_js.Future.promise Js.t Js.meth

      method write :
        Clipboard_item.t Js.js_array Js.t -> unit Js.optdef Abb_js.Future.promise Js.t Js.meth

      method writeText : Js.js_string Js.t -> unit Js.optdef Abb_js.Future.promise Js.t Js.meth
    end
end

type t = J.t Js.t

let clipboard () =
  let clipboard : t Js.optdef = Js.Unsafe.global##.navigator##.clipboard in
  Js.Optdef.to_option clipboard

let read (t : t) =
  let open Abb_js.Future.Infix_monad in
  Abb_js.Future.unsafe_of_promise t##read >>| CCFun.(Js.to_array %> CCArray.to_list)

let read_text (t : t) =
  let open Abb_js.Future.Infix_monad in
  Abb_js.Future.unsafe_of_promise t##read >>| Js.to_string

let write (t : t) items =
  Abb_js.Future.unsafe_of_promise (t##write (items |> CCArray.of_list |> Js.array))

let write_text (t : t) s = Abb_js.Future.unsafe_of_promise (t##writeText (Js.string s))
