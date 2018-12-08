val send : ?body:string -> meth:string -> url:string -> unit -> string Abb_fut.t

val send_formdata : meth:string -> url:string -> Form.formData Js.t -> unit Abb_fut.t
