type connect_err =
  [ `He_connect_err of string * string
  | `He_cancelled_err
  ]
[@@deriving show]

module Make (Abb : Abb_intf.S) : sig
  (** Connect to a host with a list of ports using the happy eyeballs
     algorithm. *)
  val connect :
    string ->
    int list ->
    ((Ipaddr.t * int) * Abb.Socket.tcp Abb.Socket.t, [> connect_err ]) result Abb.Future.t
end
