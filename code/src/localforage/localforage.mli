type t

val global : unit -> t

val create : string -> t

val destroy : t -> unit Abb_fut_js.t

val set_item : t -> key:string -> Js_of_ocaml.Js.Unsafe.any -> unit Abb_fut_js.t

val get_item : t -> string -> Js_of_ocaml.Js.Unsafe.any option Abb_fut_js.t

val remove_item : t -> string -> unit Abb_fut_js.t

val clear : t -> unit Abb_fut_js.t

val length : t -> int Abb_fut_js.t

val keys : t -> string list Abb_fut_js.t
