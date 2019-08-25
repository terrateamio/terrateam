module Fut = Abb_fut.Make (struct
  type t = unit
end)

module Channel = Abb_channel.Make (Fut)
module Channel_queue = Abb_channel_queue.Make (Fut)

let dummy_state = Abb_fut.State.create ()

let simple_send =
  Oth.test ~desc:"Sending then receiving works" ~name:"Simple Send" (fun _ ->
      let fut =
        let open Fut.Infix_monad in
        Channel_queue.T.create ()
        >>= fun queue ->
        let (r_chan, w_chan) = Channel_queue.to_abb_channel queue in
        Fut.fork (Channel.send w_chan ())
        >>= fun send_fut ->
        Channel.recv r_chan
        >>| fun r ->
        assert (r = `Ok ());
        assert (Fut.state send_fut = `Det (`Ok ()))
      in
      ignore (Fut.run_with_state fut dummy_state);
      assert (Fut.state fut = `Det ()))

let simple_recv =
  Oth.test ~desc:"Receiving then sending works" ~name:"Simple Receive" (fun _ ->
      let fut =
        let open Fut.Infix_monad in
        Channel_queue.T.create ()
        >>= fun queue ->
        let (r_chan, w_chan) = Channel_queue.to_abb_channel queue in
        Fut.fork (Channel.recv r_chan)
        >>= fun recv_fut ->
        Channel.send w_chan ()
        >>= fun r ->
        assert (r = `Ok ());
        recv_fut >>| fun r -> assert (r = `Ok ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      assert (Fut.state fut = `Det ()))

let closed_recv =
  Oth.test ~desc:"Closing then receiving is closed" ~name:"Closed Receive" (fun _ ->
      let fut =
        let open Fut.Infix_monad in
        Channel_queue.T.create ()
        >>= fun queue ->
        let (r_chan, w_chan) = Channel_queue.to_abb_channel queue in
        Channel.close_reader r_chan
        >>= fun () -> Channel.recv r_chan >>| fun r -> assert (r = `Closed)
      in
      ignore (Fut.run_with_state fut dummy_state);
      assert (Fut.state fut = `Det ()))

let closed_send =
  Oth.test ~desc:"Sending on a closed channel is closed" ~name:"Closed Send" (fun _ ->
      let fut =
        let open Fut.Infix_monad in
        Channel_queue.T.create ()
        >>= fun queue ->
        let (r_chan, w_chan) = Channel_queue.to_abb_channel queue in
        Channel.close_reader r_chan
        >>= fun () -> Channel.send w_chan () >>| fun r -> assert (r = `Closed)
      in
      ignore (Fut.run_with_state fut dummy_state);
      assert (Fut.state fut = `Det ()))

let recv_then_close =
  Oth.test ~desc:"Closing a channel triggers waiting receives" ~name:"Receive then close" (fun _ ->
      let fut =
        let open Fut.Infix_monad in
        Channel_queue.T.create ()
        >>= fun queue ->
        let (r_chan, w_chan) = Channel_queue.to_abb_channel queue in
        Fut.fork (Channel.recv r_chan)
        >>= fun recv_fut ->
        Channel.close_reader r_chan >>= fun () -> recv_fut >>| fun r -> assert (r = `Closed)
      in
      ignore (Fut.run_with_state fut dummy_state);
      assert (Fut.state fut = `Det ()))

let fast_count =
  Oth.test ~desc:"Fast count has pushback after the queue size is full" ~name:"Fast count" (fun _ ->
      let fut =
        let open Fut.Infix_monad in
        Channel_queue.T.create ~fast_count:1 ()
        >>= fun queue ->
        let (r_chan, w_chan) = Channel_queue.to_abb_channel queue in
        Fut.fork (Channel.send w_chan ())
        >>= fun send1 ->
        Fut.fork (Channel.send w_chan ())
        >>= fun send2 ->
        assert (Fut.state send1 = `Det (`Ok ()));
        assert (Fut.state send2 = `Undet);
        Channel.recv r_chan
        >>= fun r ->
        assert (r = `Ok ());
        Channel.recv r_chan >>| fun r -> assert (r = `Ok ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      assert (Fut.state fut = `Det ()))

let close_send_allows_recv =
  Oth.test
    ~desc:"Closing the send side of the queue allows receives"
    ~name:"Close Send Allows Recv"
    (fun _ ->
      let fut =
        let open Fut.Infix_monad in
        Channel_queue.T.create ~fast_count:0 ()
        >>= fun queue ->
        let (r_chan, w_chan) = Channel_queue.to_abb_channel queue in
        Fut.fork (Channel.send w_chan ())
        >>= fun send_ret ->
        Channel.close w_chan
        >>= fun () ->
        assert (Fut.state send_ret = `Undet);
        Channel.recv r_chan
        >>| fun r ->
        assert (r = `Ok ());
        assert (Fut.state send_ret = `Det (`Ok ()))
      in
      ignore (Fut.run_with_state fut dummy_state);
      assert (Fut.state fut = `Det ()))

let close_recv_aborts_all_sends =
  Oth.test
    ~desc:"Aborting the reader aborts all waiting sends"
    ~name:"Close Recv Aborts All Sends"
    (fun _ ->
      let fut =
        let open Fut.Infix_monad in
        Channel_queue.T.create ~fast_count:0 ()
        >>= fun queue ->
        let (r_chan, w_chan) = Channel_queue.to_abb_channel queue in
        Fut.fork (Channel.send w_chan ())
        >>= fun send_ret ->
        Channel.close_reader r_chan >>| fun () -> assert (Fut.state send_ret = `Aborted)
      in
      ignore (Fut.run_with_state fut dummy_state);
      assert (Fut.state fut = `Det ()))

let closed_cannot_be_aborted =
  Oth.test
    ~desc:"Aborting the result of closed call doesn't abort all"
    ~name:"closed cannot be aborted"
    (fun _ ->
      let fut =
        let open Fut.Infix_monad in
        Channel_queue.T.create ~fast_count:0 ()
        >>= fun queue ->
        let (r_chan, w_chan) = Channel_queue.to_abb_channel queue in
        Fut.fork (Channel.closed w_chan)
        >>= fun closed ->
        Fut.abort closed
        >>= fun () ->
        assert (Fut.state closed = `Aborted);
        Fut.fork (Channel.closed w_chan) >>| fun closed -> assert (Fut.state closed <> `Aborted)
      in
      ignore (Fut.run_with_state fut dummy_state);
      assert (Fut.state fut = `Det ()))

let recv_can_be_aborted =
  Oth.test ~desc:"Aborting a recv does not drop messages" ~name:"aborted does not drop" (fun _ ->
      let fut =
        let open Fut.Infix_monad in
        Channel_queue.T.create ()
        >>= fun queue ->
        let (r_chan, w_chan) = Channel_queue.to_abb_channel queue in
        Fut.fork (Channel.recv r_chan)
        >>= fun recv_fut ->
        Fut.abort recv_fut
        >>= fun () ->
        Fut.fork (Channel.send w_chan ())
        >>= fun _ -> Channel.recv r_chan >>| fun r -> assert (r = `Ok ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      assert (Fut.state fut = `Det ()))

let () =
  Random.self_init ();
  Oth.(
    run
      (parallel
         [
           simple_send;
           simple_recv;
           closed_recv;
           closed_send;
           recv_then_close;
           fast_count;
           close_send_allows_recv;
           close_recv_aborts_all_sends;
           closed_cannot_be_aborted;
           recv_can_be_aborted;
         ]))
