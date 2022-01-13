module Blob : sig
  type t

  val create : typ:string -> string list -> t

  val text : t -> string Abb_js.Future.t
end

module Clipboard_item : sig
  type t

  val create : (string * Blob.t) list -> t

  val types : t -> string list

  val get_type : t -> string -> Blob.t option Abb_js.Future.t
end

type t

val clipboard : unit -> t option

val read : t -> Clipboard_item.t list Abb_js.Future.t

val read_text : t -> string Abb_js.Future.t

val write : t -> Clipboard_item.t list -> unit Abb_js.Future.t

val write_text : t -> string -> unit Abb_js.Future.t
