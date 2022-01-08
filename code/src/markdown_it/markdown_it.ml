open Js_of_ocaml

class type options =
  object
    method highlight :
      (Js.js_string Js.t -> Js.js_string Js.t -> Js.js_string Js.t) Js.callback Js.readonly_prop
  end

class type lang =
  object
    method language : Js.js_string Js.t Js.readonly_prop
  end

class type highlight_res =
  object
    method value : Js.js_string Js.t Js.readonly_prop
  end

class type highlight =
  object
    method getLanguage : Js.js_string Js.t -> unit Js.optdef Js.meth

    method highlight : Js.js_string Js.t -> lang Js.t -> highlight_res Js.t Js.meth
  end

class type markdownit =
  object
    method render : Js.js_string Js.t -> Js.js_string Js.t Js.meth
  end

let render str =
  let hljs : highlight Js.t = Js.Unsafe.global##.hljs in
  let options : options Js.t =
    object%js
      val highlight =
        Js.wrap_callback (fun str lang ->
            if Js.to_string lang <> "" && Js.Optdef.test (hljs##getLanguage lang) then
              (hljs##highlight
                 str
                 (object%js
                    val language = lang
                 end))##.value
            else
              Js.string "")
    end
  in
  let constr : (options Js.t -> markdownit Js.t) Js.constr = Js.Unsafe.global##.markdownit in
  let markdown_it = new%js constr options in
  Js.to_string (markdown_it##render (Js.string str))
