val send : ?body:string -> meth:string -> url:string -> unit -> string Abb_fut.t

val send_formdata :
  meth:string ->
  url:string ->
  Js_of_ocaml.Form.formData Js_of_ocaml.Js.t ->
  unit Abb_fut.t
