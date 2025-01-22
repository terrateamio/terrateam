module C = Ctypes
module F = Foreign
module P = PosixTypes

module Tls_config = struct
  open C

  type t = unit ptr

  let t : t typ = ptr void
  let tls_config_new = F.foreign "tls_config_new" C.(void @-> returning t)
  let tls_config_free = F.foreign "tls_config_free" C.(t @-> returning void)
  let tls_config_error = F.foreign "tls_config_error" C.(t @-> returning string)
  let tls_config_set_ca_file = F.foreign "tls_config_set_ca_file" C.(t @-> string @-> returning int)
  let tls_config_set_ca_path = F.foreign "tls_config_set_ca_path" C.(t @-> string @-> returning int)
  let tls_config_set_alpn = F.foreign "tls_config_set_alpn" C.(t @-> string @-> returning int)

  let tls_config_set_cert_file =
    F.foreign "tls_config_set_cert_file" C.(t @-> string @-> returning int)

  let tls_config_set_key_file =
    F.foreign "tls_config_set_key_file" C.(t @-> string @-> returning int)

  let tls_config_verify = F.foreign "tls_config_verify" C.(t @-> returning void)

  let tls_config_insecure_noverifycert =
    F.foreign "tls_config_insecure_noverifycert" C.(t @-> returning void)

  let tls_config_insecure_noverifyname =
    F.foreign "tls_config_insecure_noverifyname" C.(t @-> returning void)

  let tls_config_insecure_noverifytime =
    F.foreign "tls_config_insecure_noverifytime" C.(t @-> returning void)

  let tls_config_set_protocols =
    F.foreign "tls_config_set_protocols" C.(t @-> uint32_t @-> returning int)

  let tls_config_set_ciphers = F.foreign "tls_config_set_ciphers" C.(t @-> string @-> returning int)
end

module Tls = struct
  open C

  type t = unit ptr

  let t : t typ = ptr void
  let tls_client = F.foreign "tls_client" C.(void @-> returning t)
  let tls_server = F.foreign "tls_server" C.(void @-> returning t)
  let tls_free = F.foreign "tls_free" C.(t @-> returning void)
  let tls_connect_socket = F.foreign "tls_connect_socket" C.(t @-> int @-> string @-> returning int)
  let tls_accept_socket = F.foreign "tls_accept_socket" C.(t @-> ptr t @-> int @-> returning int)
  let tls_read = F.foreign "tls_read" C.(t @-> ocaml_bytes @-> size_t @-> returning P.ssize_t)
  let tls_write = F.foreign "tls_write" C.(t @-> ocaml_bytes @-> size_t @-> returning P.ssize_t)
  let tls_handshake = F.foreign "tls_handshake" C.(t @-> returning int)
  let tls_close = F.foreign "tls_close" C.(t @-> returning int)
  let tls_reset = F.foreign "tls_reset" C.(t @-> returning void)
  let tls_error = F.foreign "tls_error" C.(t @-> returning string)
  let tls_conn_version = F.foreign "tls_conn_version" C.(t @-> returning string)
  let tls_conn_cipher = F.foreign "tls_conn_cipher" C.(t @-> returning string)
  let tls_peer_cert_provided = F.foreign "tls_peer_cert_provided" C.(t @-> returning string)

  let tls_peer_cert_contains_name =
    F.foreign "tls_peer_cert_contains_name" C.(t @-> string @-> returning int)

  let tls_peer_cert_subject = F.foreign "tls_peer_cert_subject" C.(t @-> returning string)
  let tls_peer_cert_issuer = F.foreign "tls_peer_cert_issuer" C.(t @-> returning string)
  let tls_peer_cert_hash = F.foreign "tls_peer_cert_hash" C.(t @-> returning string)

  let tls_peer_cert_notbefore =
    F.foreign "tls_peer_cert_notbefore" C.(t @-> returning PosixTypes.time_t)

  let tls_peer_cert_notafter =
    F.foreign "tls_peer_cert_notafter" C.(t @-> returning PosixTypes.time_t)
end

let tls_init = F.foreign "tls_init" C.(void @-> returning int)
let tls_configure = F.foreign "tls_configure" C.(Tls.t @-> Tls_config.t @-> returning int)
