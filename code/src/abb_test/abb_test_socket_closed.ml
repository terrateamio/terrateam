module Make (Abb : Abb_intf.S) = struct
  module Oth_abb = Oth_abb.Make (Abb)

  (* A closed socket must reject further operations, and [close] must be
     idempotent (a second close cannot fail or double-close a recycled fd). *)
  let socket_closed_ops_fail =
    Oth_abb.test
      ~desc:"Closed socket rejects ops and close is idempotent"
      ~name:"socket_closed_ops_fail"
      (fun () ->
        let open Abb.Future.Infix_monad in
        match Abb.Socket.Tcp.create ~domain:Abb_intf.Socket.Domain.Inet4 with
        | Error _ -> Oth.Assert.false_ "socket create failed"
        | Ok sock ->
            Abb.Socket.close sock
            >>= fun _ ->
            Abb.Socket.close sock
            >>= fun second_close ->
            Oth.Assert.true_ "second close should succeed" (Result.is_ok second_close);
            let buf = Bytes.create 8 in
            Abb.Socket.Tcp.recv sock ~buf ~pos:0 ~len:8
            >>= fun recv_res ->
            Oth.Assert.true_ "recv on a closed socket should fail" (Result.is_error recv_res);
            let wb = Abb_intf.Write_buf.{ buf = Bytes.of_string "x"; pos = 0; len = 1 } in
            Abb.Socket.Tcp.send sock ~bufs:[ wb ]
            >>= fun send_res ->
            Oth.Assert.true_ "send on a closed socket should fail" (Result.is_error send_res);
            Abb.Future.return ())

  let test = Oth_abb.serial [ socket_closed_ops_fail ]
end
