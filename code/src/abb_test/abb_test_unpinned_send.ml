module Unix = UnixLabels

module Make (Abb : Abb_intf.S) = struct
  module Oth_abb = Oth_abb.Make (Abb)
  module Fut_comb = Abb_future_combinators.Make (Abb.Future)

  (* Regression test for the capture-eagerly invariant on [Socket.Tcp.send]
     (RFD 675, "Capture-eagerly invariant for unpinned_ctx").

     An unpinned task whose body issues a socket send *before its first async
     suspension* must still have that send's poll callback serialized onto the
     task's worker domain.  The send's [with_state] closure runs during the
     task's initial [run_with_state] advance, by which point the
     [set_data {unpinned = Some _}] chain-data scope has been restored.  If
     [send] reads [current_unpinned ()] there (lazily) instead of capturing it
     eagerly at the call site, the poll op is tagged pinned, its completion
     runs inline on the loop domain, and it drives the task's [Abb_fut] State
     while the worker domain still owns it -- the debug build then aborts with a
     cross-domain race (exit 134), failing this test by killing the process.

     Each task forks a send (the "poison" op, submitted during the initial
     advance) and then spins a CPU loop that holds its worker State on the
     worker domain, giving the loop domain a wide window to fire the poisoned
     poll concurrently -- making the race deterministic rather than flaky. *)

  let loopback_addr port = Abb_intf.Socket.Sockaddr.(Inet { addr = Unix.inet_addr_loopback; port })

  let with_server f =
    let open Abb.Future.Infix_monad in
    let srv = CCResult.get_exn (Abb.Socket.Tcp.create ~domain:Abb_intf.Socket.Domain.Inet4) in
    ignore (Abb.Socket.Tcp.bind srv (loopback_addr 0));
    ignore (Abb.Socket.listen srv ~backlog:128);
    let port =
      match Abb.Socket.getsockname srv with
      | Abb_intf.Socket.Sockaddr.Inet { Abb_intf.Socket.Sockaddr.port; _ } -> port
      | Abb_intf.Socket.Sockaddr.Unix _ -> Oth.Assert.false_ "expected an inet address"
    in
    (* Accept and drain connections in the background so client sends never
       block on a full kernel buffer.  Both loops unwind once [srv]/the clients
       close at end of test. *)
    let rec drain c =
      let buf = Bytes.create 4096 in
      Abb.Socket.Tcp.recv c ~buf ~pos:0 ~len:(Bytes.length buf)
      >>= function
      | Ok n when n > 0 -> drain c
      | _ -> Abb.Socket.close c >>= fun _ -> Abb.Future.return ()
    in
    let rec accept_loop () =
      Abb.Socket.accept srv
      >>= function
      | Ok c -> Abb.Future.fork (drain c) >>= fun _ -> accept_loop ()
      | Error _ -> Abb.Future.return ()
    in
    Abb.Future.fork (accept_loop ())
    >>= fun _ -> f port >>= fun r -> Abb.Socket.close srv >>= fun _ -> Abb.Future.return r

  let connect port =
    let open Abb.Future.Infix_monad in
    let sock = CCResult.get_exn (Abb.Socket.Tcp.create ~domain:Abb_intf.Socket.Domain.Inet4) in
    Abb.Socket.Tcp.connect sock (loopback_addr port)
    >>= function
    | Ok () -> Abb.Future.return sock
    | Error _ -> Oth.Assert.false_ "connect failed"

  let poison_body sock () =
    let open Abb.Future.Infix_monad in
    let buf = Bytes.of_string "x" in
    let bufs = Abb_intf.Write_buf.[ { buf; pos = 0; len = Bytes.length buf } ] in
    (* Fork the send: its poll op is submitted during the task's initial advance
       (where the chain data has been restored), then it runs concurrently. *)
    Abb.Future.fork (Abb.Socket.Tcp.send sock ~bufs)
    >>= fun send_handle ->
    (* Synchronous CPU loop: holds this task's worker State while the loop domain
       fires the poisoned poll. *)
    let s = ref 0 in
    for i = 1 to 300_000_000 do
      s := !s + (i land 7)
    done;
    send_handle >>= fun _ -> Abb.Future.return !s

  let test_sync_send =
    Oth_abb.test
      ~desc:"An unpinned task's synchronous send must not drive its State from the loop domain"
      ~name:"Unpinned: synchronous send serialized onto worker domain"
      (fun () ->
        let open Abb.Future.Infix_monad in
        with_server (fun port ->
            let task _ =
              connect port
              >>= fun sock ->
              Abb.Task.run ~pinned:false (poison_body sock)
              >>= fun fut ->
              fut >>= fun _ -> Abb.Socket.close sock >>= fun _ -> Abb.Future.return ()
            in
            Fut_comb.List.map ~f:task (CCList.init 6 CCFun.id) >>| fun (_ : unit list) -> ()))

  let test = Oth_abb.serial [ test_sync_send ]
end
