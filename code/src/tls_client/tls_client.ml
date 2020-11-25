external int_of_fd : Unix.file_descr -> int = "%identity"

let run_client client =
  let open CCResult.Infix in
  let cfg = Otls.Tls_config.create () in
  Otls.Tls_config.insecure_noverifycert cfg;
  (* Otls.Tls_config.set_ca_file cfg "/tmp/secrets/server.pem" *)
  (* >>= fun () -> *)
  Otls.configure client cfg
  >>= fun () ->
  let socket = Unix.(socket PF_INET SOCK_STREAM 0) in
  Unix.connect socket Unix.(ADDR_INET (inet_addr_loopback, 8080));
  let fd = int_of_fd socket in
  Otls.Tls.connect_socket client fd "127.0.0.1"
  >>= fun () ->
  let buf = Bytes.of_string "Hello\n" in
  Otls.Tls.write client ~pos:0 ~len:(Bytes.length buf) buf
  >>= fun n ->
  assert (n = Bytes.length buf);
  Unix.close socket;
  Otls.Tls_config.destroy cfg;
  Ok ()

let main () =
  let client = Otls.Tls.client () in
  match run_client client with
    | Ok () ->
        Otls.Tls.destroy client;
        Ok ()
    | Error `Error ->
        let error = Otls.Tls.error client in
        print_endline error;
        Otls.Tls.destroy client;
        Error `Error
    | Error `Want_pollin | Error `Want_pollout -> assert false

let () =
  match main () with
    | Ok ()        -> print_endline "Great success"
    | Error `Error -> print_endline "Giant failure"
