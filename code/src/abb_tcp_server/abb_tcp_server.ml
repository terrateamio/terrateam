module Make (Abb : Abb_intf.S) = struct
  module Channel = Abb_channel.Make (Abb.Future)
  module Channel_queue = Abb_channel_queue.Make (Abb.Future)
  module Fut_comb = Abb_future_combinators.Make (Abb.Future)

  type reader = Abb_channel.Make(Abb.Future).reader
  type ('a, 'm) channel = ('a, 'm) Abb_channel.Make(Abb.Future).t
  type t = (reader, Abb.Socket.tcp Abb.Socket.t) channel

  type errors =
    [ Abb_intf.Errors.bind
    | Abb_intf.Errors.sock_create
    | Abb_intf.Errors.listen
    ]

  let rec tcp_accept_loop sock wc =
    let open Abb.Future.Infix_monad in
    Abb.Socket.accept sock
    >>= function
    | Ok conn -> send_conn sock wc conn
    | Error `E_connection_aborted ->
        (* In the case the client disconnected between accepting and getting here,
           just ignore the error. *)
        tcp_accept_loop sock wc
    | Error `E_bad_file ->
        (* This should never happen. *)
        assert false
    | Error `E_file_table_full ->
        (* FIXME: Find a better way to handle this.  It would be nice to be able to
           propagate this error up. *)
        Channel.close wc >>= fun () -> failwith "file table full"
    | Error `E_invalid ->
        (* This should never happen. *)
        assert false
    | Error (`Unexpected _) ->
        (* This should never happen. *)
        assert false

  and send_conn sock wc conn =
    let open Abb.Future.Infix_monad in
    Channel.send wc conn
    >>= function
    | `Ok () -> tcp_accept_loop sock wc
    | `Closed ->
        Fut_comb.ignore (Abb.Socket.close sock)
        >>= fun () -> Fut_comb.ignore (Abb.Socket.close conn)

  let run ?(backlog = 128) sockaddr =
    let open Fut_comb.Infix_result_monad in
    Abb.Future.return (Abb.Socket.Tcp.create ~domain:Abb_intf.Socket.Domain.Inet4)
    >>= fun tcp ->
    Abb.Future.return (Abb.Socket.Tcp.bind tcp sockaddr)
    >>= fun () ->
    Abb.Future.return (Abb.Socket.listen tcp ~backlog)
    >>= fun () ->
    Fut_comb.to_result (Channel_queue.T.create ~fast_count:1000 ())
    >>= fun queue ->
    let rc, wc = Channel_queue.to_abb_channel queue in
    Fut_comb.to_result (Abb.Future.fork (tcp_accept_loop tcp wc))
    >>= fun _ -> Abb.Future.return (Ok rc)
end
