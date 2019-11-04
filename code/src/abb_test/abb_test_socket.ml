module Unix = UnixLabels

module Make (Abb : Abb_intf.S) = struct
  module Oth_abb = Oth_abb.Make (Abb)

  let read_client c =
    let open Abb.Future.Infix_monad in
    let buf = Bytes.create 100 in
    Abb.Socket.Tcp.recv c ~buf ~pos:0 ~len:(Bytes.length buf)
    >>= function
    | Ok n    ->
        Printf.printf "Received message %d %s\n%!" n (Bytes.sub_string buf 0 n);
        Abb.Future.return ()
    | Error _ -> failwith "Read error"

  let connect_server port =
    let open Abb.Future.Infix_monad in
    Abb.Socket.getaddrinfo
      ~hints:
        Abb_intf.Socket.
          [ Addrinfo_hints.Socket_type Socket_type.Stream; Addrinfo_hints.Family Domain.Inet4 ]
      Abb_intf.Socket.Addrinfo_query.(Host_service ("localhost", string_of_int port))
    >>= function
    | Ok rs   -> (
        let addr = (List.hd rs).Abb_intf.Socket.Addrinfo.addr in
        let tcp = CCResult.get_exn (Abb.Socket.Tcp.create ~domain:Abb_intf.Socket.Domain.Inet4) in
        let buf = Bytes.of_string "Hello, World" in
        let pos = 0 in
        let len = Bytes.length buf in
        Printf.printf "Trying to connect\n%!";
        Abb.Socket.Tcp.connect tcp addr
        >>= function
        | Ok ()   -> (
            Printf.printf "Connected\n";
            Abb.Socket.Tcp.send tcp ~bufs:Abb_intf.Write_buf.[ { buf; pos; len } ]
            >>= function
            | Ok n    ->
                Printf.printf "Sent %d bytes, closing\n%!" n;
                Abb.Socket.close tcp
            | Error _ ->
                Printf.printf "Failed to send\n%!";
                Abb.Socket.close tcp )
        | Error _ -> failwith "connect error" )
    | Error _ -> failwith "getaddrinfo error"

  let start_server cb =
    let open Abb.Future.Infix_monad in
    let open Abb.Future.Infix_app in
    Printf.printf "Starting server\n%!";
    let addr = Abb_intf.Socket.Sockaddr.(Inet { addr = Unix.inet_addr_any; port = 0 }) in
    let tcp = CCResult.get_exn (Abb.Socket.Tcp.create ~domain:Abb_intf.Socket.Domain.Inet4) in
    ignore (Abb.Socket.Tcp.bind tcp addr);
    ignore (Abb.Socket.listen tcp ~backlog:128);
    let port =
      let module Sa = Abb_intf.Socket.Sockaddr in
      match Abb.Socket.getsockname tcp with
        | Sa.Inet { Sa.port; _ } -> port
        | Sa.Unix _              -> assert false
    in
    let cb_fut = cb port in
    Printf.printf "Waiting on accept\n";
    let accept_fut =
      Printf.printf "Accepting...\n%!";
      Abb.Socket.accept tcp
      >>= function
      | Ok c    ->
          Printf.printf "Socket accepted\n%!";
          read_client c >>= fun () -> Abb.Socket.close tcp >>= fun _ -> Abb.Future.return ()
      | Error _ ->
          Printf.printf "Accept failed\n%!";
          failwith "accept failed"
    in
    let both _ _ = () in
    both <$> accept_fut <*> cb_fut >>| fun () -> ()

  let socket_test =
    Oth_abb.test ~desc:"Simple socket server test" ~name:"Socket server test" (fun () ->
        start_server connect_server)

  let test = Oth_abb.serial [ socket_test ]
end
