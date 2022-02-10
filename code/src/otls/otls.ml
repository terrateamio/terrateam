module Stubs = Otls_bindings.Stubs (Otls_stubs)

type err = [ `Error ]

type io_err =
  [ err
  | `Want_pollin
  | `Want_pollout
  ]

module Tls_protocols = struct
  type t =
    | TLSv1_0
    | TLSv1_1
    | TLSv1_2

  let to_int = function
    | TLSv1_0 -> Stubs.tls_protocol_tlsv1_0
    | TLSv1_1 -> Stubs.tls_protocol_tlsv1_1
    | TLSv1_2 -> Stubs.tls_protocol_tlsv1_2

  let of_int = function
    | n when n = Stubs.tls_protocol_tlsv1_0 -> Some TLSv1_0
    | n when n = Stubs.tls_protocol_tlsv1_1 -> Some TLSv1_1
    | n when n = Stubs.tls_protocol_tlsv1_2 -> Some TLSv1_2
    | _ -> None
end

module Tls_ciphers = struct
  type t =
    | Secure
    | Default
    | Legacy
    | Insecure
    | Ciphers of string list

  let to_string = function
    | Secure -> "secure"
    | Default -> "default"
    | Legacy -> "legacy"
    | Insecure -> "insecure"
    | Ciphers cphrs -> String.concat ":" cphrs
end

module Tls_config = struct
  type t = Otls_c_bindings.Tls_config.t

  let create () = Otls_c_bindings.Tls_config.tls_config_new ()
  let destroy t = Otls_c_bindings.Tls_config.tls_config_free t

  let set_ca_file t fname =
    match Otls_c_bindings.Tls_config.tls_config_set_ca_file t fname with
    | -1 -> Error `Error
    | _ -> Ok ()

  let set_cert_file t fname =
    match Otls_c_bindings.Tls_config.tls_config_set_cert_file t fname with
    | -1 -> Error `Error
    | _ -> Ok ()

  let set_key_file t fname =
    match Otls_c_bindings.Tls_config.tls_config_set_key_file t fname with
    | -1 -> Error `Error
    | _ -> Ok ()

  let verify t = Otls_c_bindings.Tls_config.tls_config_verify t
  let insecure_noverifycert t = Otls_c_bindings.Tls_config.tls_config_insecure_noverifycert t
  let insecure_noverifyname t = Otls_c_bindings.Tls_config.tls_config_insecure_noverifyname t
  let insecure_noverifytime t = Otls_c_bindings.Tls_config.tls_config_insecure_noverifytime t

  let set_protocols t protos =
    let bitmask =
      ListLabels.fold_left ~f:(fun bm v -> bm lor Tls_protocols.to_int v) ~init:0 protos
    in
    let ret =
      Otls_c_bindings.Tls_config.tls_config_set_protocols t (Unsigned.UInt32.of_int bitmask)
    in
    assert (ret = 0);
    ()

  let set_ciphers t ciphers =
    let ret = Otls_c_bindings.Tls_config.tls_config_set_ciphers t (Tls_ciphers.to_string ciphers) in
    match ret with
    | -1 -> Error `Error
    | _ -> Ok ()
end

module Tls = struct
  type server
  type client
  type 'a t = Otls_c_bindings.Tls.t

  let client () = Otls_c_bindings.Tls.tls_client ()
  let server () = Otls_c_bindings.Tls.tls_server ()

  let destroy t =
    ignore (Otls_c_bindings.Tls.tls_close t);
    Otls_c_bindings.Tls.tls_free t

  let connect_socket t socket servername =
    match Otls_c_bindings.Tls.tls_connect_socket t socket servername with
    | -1 -> Error `Error
    | _ -> Ok ()

  let accept_socket t socket =
    let tls_ptr = Ctypes.(allocate_n Otls_c_bindings.Tls.t ~count:1) in
    match Otls_c_bindings.Tls.tls_accept_socket t tls_ptr socket with
    | -1 -> Error `Error
    | _ -> Ok Ctypes.(!@tls_ptr)

  let read t ~pos ~len bytes =
    let buf = Ctypes.(ocaml_bytes_start bytes +@ pos) in
    match Otls_c_bindings.Tls.tls_read t buf (Unsigned.Size_t.of_int len) with
    | n when n = PosixTypes.Ssize.minus_one -> Error `Error
    | n when n = Stubs.tls_want_pollin -> Error `Want_pollin
    | n when n = Stubs.tls_want_pollout -> Error `Want_pollout
    | n -> Ok (PosixTypes.Ssize.to_int n)

  let write t ~pos ~len bytes =
    let buf = Ctypes.(ocaml_bytes_start bytes +@ pos) in
    match Otls_c_bindings.Tls.tls_write t buf (Unsigned.Size_t.of_int len) with
    | n when n = PosixTypes.Ssize.minus_one -> Error `Error
    | n when n = Stubs.tls_want_pollin -> Error `Want_pollin
    | n when n = Stubs.tls_want_pollout -> Error `Want_pollout
    | n -> Ok (PosixTypes.Ssize.to_int n)

  let error = Otls_c_bindings.Tls.tls_error
  let conn_version = Otls_c_bindings.Tls.tls_conn_version
  let conn_cipher = Otls_c_bindings.Tls.tls_conn_cipher
  let peer_cert_provided = Otls_c_bindings.Tls.tls_peer_cert_provided

  let peer_cert_contains_name t name =
    match Otls_c_bindings.Tls.tls_peer_cert_contains_name t name with
    | 0 -> false
    | _ -> true

  let peer_cert_subject = Otls_c_bindings.Tls.tls_peer_cert_subject
  let peer_cert_issuer = Otls_c_bindings.Tls.tls_peer_cert_issuer
  let peer_cert_hash = Otls_c_bindings.Tls.tls_peer_cert_hash
  let peer_cert_notbefore _ = failwith "nyi"
  let peer_cert_notafter _ = failwith "nyi"
end

let configure tls tls_config =
  match Otls_c_bindings.tls_configure tls tls_config with
  | -1 -> Error `Error
  | _ -> Ok ()

(* Initialize TLS. *)
let () =
  match Otls_c_bindings.tls_init () with
  | -1 -> assert false
  | _ -> ()
