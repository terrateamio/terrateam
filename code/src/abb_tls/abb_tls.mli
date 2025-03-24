(** Wrapper for Otls. *)

type err = [ `Error ] [@@deriving show, eq]

module Make (Abb : Abb_intf.S with type Native.t = Unix.file_descr) : sig
  module Buffered : module type of Abb_io_buffered.Make (Abb.Future)

  (** Convert a TCP socket, with the provided TLS config, and the servername into a TLS buffered
      I/O. *)
  val client_tcp :
    ?size:int ->
    Abb.Socket.tcp Abb.Socket.t ->
    Otls.Tls_config.t ->
    string ->
    (Buffered.reader Buffered.t * Buffered.writer Buffered.t, [> err ]) result

  (** Convert a client socket which connected on the socket that corresponds to the Tls instance of
      the server into a TLS buffered I/O. *)
  val server_tcp :
    ?size:int ->
    Otls.Tls.server Otls.Tls.t ->
    Abb.Socket.tcp Abb.Socket.t ->
    (Buffered.reader Buffered.t * Buffered.writer Buffered.t, [> err ]) result
end
