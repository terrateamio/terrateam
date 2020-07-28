open Js_of_ocaml

class type options =
  object
    method simplifiedAutoLink : bool Js.t Js.readonly_prop
  end

class type converter =
  object
    method makeHtml : Js.js_string Js.t -> Js.js_string Js.t Js.meth
  end

let make_html str =
  let constr : (options Js.t -> converter Js.t) Js.constr =
    Js.Unsafe.global ##. showdown ##. Converter
  in
  let options : options Js.t =
    object%js
      val simplifiedAutoLink = Js._true
    end
  in
  let converter = new%js constr options in
  Js.to_string (converter##makeHtml (Js.string str))
