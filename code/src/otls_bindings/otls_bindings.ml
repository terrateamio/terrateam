module C = Ctypes
module F = Foreign

module Stubs =
functor
  (S : Cstubs_structs.TYPE)
  ->
  struct
    let tls_want_pollin = S.(constant "TLS_WANT_POLLIN" (lift_typ PosixTypes.ssize_t))
    let tls_want_pollout = S.(constant "TLS_WANT_POLLOUT" (lift_typ PosixTypes.ssize_t))
    let tls_protocol_tlsv1_0 = S.(constant "TLS_PROTOCOL_TLSv1_0" int)
    let tls_protocol_tlsv1_1 = S.(constant "TLS_PROTOCOL_TLSv1_1" int)
    let tls_protocol_tlsv1_2 = S.(constant "TLS_PROTOCOL_TLSv1_2" int)
  end
