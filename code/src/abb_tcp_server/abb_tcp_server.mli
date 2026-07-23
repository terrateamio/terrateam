module Make (Abb : Abb_intf.S) : sig
  type t = Abb.Socket.tcp Abb.Socket.t Abb.Chan.t

  type errors =
    [ Abb_intf.Errors.bind
    | Abb_intf.Errors.sock_create
    | Abb_intf.Errors.listen
    ]

  val run : ?backlog:int -> Abb_intf.Socket.Sockaddr.t -> (t, [> errors ]) result Abb.Future.t
end
