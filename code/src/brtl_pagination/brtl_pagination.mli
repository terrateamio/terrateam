module type S = sig
  type elt

  type t

  val compare : elt -> elt -> int

  val to_paginate : elt -> string list

  val has_another_page : t -> bool

  val items : t -> elt list
end

module Make (M : S) : sig
  type t

  val make : ?page_param:string -> M.t -> Uri.t -> t option

  val to_next : t -> Uri.t option

  val to_prev : t -> Uri.t option

  val items : t -> M.elt list
end
