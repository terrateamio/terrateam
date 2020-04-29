module List = ListLabels

type err = [ `Error ]

external int_of_fd : Unix.file_descr -> int = "%identity"

module Make (Abb : Abb_intf.S with type Native.t = Unix.file_descr) = struct
  module Fut_comb = Abb_future_combinators.Make (Abb.Future)
  module Buffered = Abb_io_buffered.Make (Abb.Future)

  let make_buffered sock tls =
    let rec read ~buf ~pos ~len =
      assert (pos >= 0);
      assert (len > 0);
      match Otls.Tls.read tls ~pos ~len buf with
        | Ok n                -> Abb.Future.return (Ok n)
        | Error `Want_pollin  ->
            let open Abb.Future.Infix_monad in
            Abb.Socket.readable sock >>= fun () -> read ~buf ~pos ~len
        | Error `Want_pollout ->
            let open Abb.Future.Infix_monad in
            Abb.Socket.writable sock >>= fun () -> read ~buf ~pos ~len
        | Error `Error        -> assert false
    in
    let rec write ~bufs =
      match bufs with
        | [] -> Abb.Future.return (Ok 0)
        | { Abb_intf.Write_buf.buf; pos; len } :: bs -> (
            assert (pos >= 0);
            assert (len > 0);
            match Otls.Tls.write tls ~pos ~len buf with
              | Ok n when n = len ->
                  let open Fut_comb.Infix_result_monad in
                  write ~bufs:bs >>= fun n' -> Abb.Future.return (Ok (n + n'))
              | Ok n ->
                  let open Fut_comb.Infix_result_monad in
                  write ~bufs:Abb_intf.Write_buf.({ buf; pos = pos + n; len = len - n } :: bs)
                  >>= fun n' -> Abb.Future.return (Ok (n + n'))
              | Error `Want_pollin ->
                  let open Abb.Future.Infix_monad in
                  Abb.Socket.readable sock >>= fun () -> write ~bufs
              | Error `Want_pollout ->
                  let open Abb.Future.Infix_monad in
                  Abb.Socket.writable sock >>= fun () -> write ~bufs
              | Error `Error -> assert false )
    in
    let close () =
      let open Abb.Future.Infix_monad in
      Otls.Tls.destroy tls;
      Abb.Socket.close sock >>| fun _ -> Ok ()
    in
    Buffered.of_view Buffered.View.{ read; write; close }

  let client_tcp sock conf servername =
    let open CCResult.Infix in
    let client = Otls.Tls.client () in
    Otls.configure client conf
    >>= fun () ->
    Otls.Tls.connect_socket client (int_of_fd (Abb.Socket.Tcp.to_native sock)) servername
    >>= fun () -> Ok (make_buffered sock client)

  let server_tcp server client_sock =
    let open CCResult.Infix in
    Otls.Tls.accept_socket server (int_of_fd (Abb.Socket.Tcp.to_native client_sock))
    >>= fun client -> Ok (make_buffered client_sock client)
end
