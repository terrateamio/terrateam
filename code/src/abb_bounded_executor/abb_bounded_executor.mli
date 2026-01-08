module Make (Fut : Abb_intf.Future.S) : sig
  type t

  val create : slots:int -> unit -> t Fut.t
  val run : t -> (unit -> 'a Fut.t) -> 'a Fut.t
end
