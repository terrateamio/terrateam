(** Hostname resolution tests via [Abb_intf.Socket.getaddrinfo]. *)
module Make (_ : Abb_intf.S) : sig
  val test : Oth.Test.t
end
