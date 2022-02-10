type err = [ `Error ]

type io_err =
  [ err
  | `Want_pollin
  | `Want_pollout
  ]

module Tls_protocols : sig
  type t =
    | TLSv1_0
    | TLSv1_1
    | TLSv1_2
end

module Tls_ciphers : sig
  type t =
    | Secure
    | Default
    | Legacy
    | Insecure
    | Ciphers of string list
end

module Tls_config : sig
  type t

  val create : unit -> t
  val destroy : t -> unit
  val set_ca_file : t -> string -> (unit, [> err ]) result
  val set_cert_file : t -> string -> (unit, [> err ]) result
  val set_key_file : t -> string -> (unit, [> err ]) result
  val verify : t -> unit
  val insecure_noverifycert : t -> unit
  val insecure_noverifyname : t -> unit
  val insecure_noverifytime : t -> unit
  val set_protocols : t -> Tls_protocols.t list -> unit
  val set_ciphers : t -> Tls_ciphers.t -> (unit, [> err ]) result
end

module Tls : sig
  type server
  type client
  type 'a t

  val client : unit -> client t
  val server : unit -> server t
  val destroy : 'a t -> unit
  val connect_socket : client t -> int -> string -> (unit, [> err ]) result
  val accept_socket : server t -> int -> (client t, [> err ]) result
  val read : 'a t -> pos:int -> len:int -> bytes -> (int, [> io_err ]) result
  val write : 'a t -> pos:int -> len:int -> bytes -> (int, [> io_err ]) result
  val error : 'a t -> string
  val conn_version : 'a t -> string
  val conn_cipher : 'a t -> string
  val peer_cert_provided : 'a t -> string
  val peer_cert_contains_name : 'a t -> string -> bool
  val peer_cert_subject : 'a t -> string
  val peer_cert_issuer : 'a t -> string
  val peer_cert_hash : 'a t -> string
  val peer_cert_notbefore : 'a t -> float
  val peer_cert_notafter : 'a t -> float
end

val configure : 'a Tls.t -> Tls_config.t -> (unit, [> err ]) result
