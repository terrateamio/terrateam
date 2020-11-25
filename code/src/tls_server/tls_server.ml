external int_of_fd : Unix.file_descr -> int = "%identity"

let rec read_all_bytes tls buf =
  let open CCResult.Infix in
  Otls.Tls.read tls ~pos:0 ~len:(Bytes.length buf) buf
  >>= function
  | 0 -> Ok ()
  | n ->
      output_substring stdout (Bytes.to_string buf) 0 n;
      read_all_bytes tls buf

let main () =
  let open CCResult.Infix in
  let cfg = Otls.Tls_config.create () in
  let server = Otls.Tls.server () in
  Otls.Tls_config.set_cert_file cfg "/tmp/secrets/server.pem"
  >>= fun () ->
  Otls.Tls_config.set_key_file cfg "/tmp/secrets/server.key"
  >>= fun () ->
  Otls.configure server cfg
  >>= fun () ->
  let socket = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
  Unix.bind socket Unix.(ADDR_INET (inet_addr_any, 8080));
  Unix.listen socket 25;
  let (client, _) = Unix.accept socket in
  let fd = int_of_fd client in
  Otls.Tls.accept_socket server fd
  >>= fun client_tls ->
  let buf = Bytes.create 1024 in
  read_all_bytes client_tls buf
  >>= fun () ->
  Unix.close client;
  Unix.close socket;
  Otls.Tls.destroy server;
  Otls.Tls_config.destroy cfg;
  Ok ()

let () =
  match main () with
    | Ok () -> print_endline "Great success"
    | Error `Error -> print_endline "Giant failure"
    | Error `Want_pollin | Error `Want_pollout -> assert false
