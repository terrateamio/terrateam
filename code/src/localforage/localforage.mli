type t

module Typed : sig
  type 'a t

  val create : encode:('a -> string) -> decode:(string -> 'a option) -> string -> 'a t

  val destroy : 'a t -> unit Abb_fut_js.t

  val set_item : 'a t -> key:string -> 'a -> unit Abb_fut_js.t

  val get_item : 'a t -> string -> 'a option Abb_fut_js.t

  val remove_item : 'a t -> string -> unit Abb_fut_js.t

  val clear : 'a t -> unit Abb_fut_js.t

  val length : 'a t -> int Abb_fut_js.t

  val keys : 'a t -> string list Abb_fut_js.t
end

val create : string -> t

val destroy : t -> unit Abb_fut_js.t

val set_item : t -> key:string -> string -> unit Abb_fut_js.t

val get_item : t -> string -> string option Abb_fut_js.t

val remove_item : t -> string -> unit Abb_fut_js.t

val clear : t -> unit Abb_fut_js.t

val length : t -> int Abb_fut_js.t

val keys : t -> string list Abb_fut_js.t
