module Make(Abb : Abb_intf.S) : sig
  type reader = Abb_channel.Make(Abb.Future).reader
  type ('a, 'm) channel = ('a, 'm) Abb_channel.Make(Abb.Future).t
  type t = (reader, Abb.Socket.tcp Abb.Socket.t) channel

  type errors = [ Abb_intf.Errors.bind
                | Abb_intf.Errors.sock_create
                | Abb_intf.Errors.listen
                ]

  val run : ?backlog:int -> Abb_intf.Socket.Sockaddr.t -> (t, [> errors ]) result Abb.Future.t
end
