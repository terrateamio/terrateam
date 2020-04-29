module Make (Fut : Abb_intf.Future.S) = struct
  module T = struct
    type 'a t = {
      queue : ('a * unit Fut.Promise.t) Queue.t;
      fast_count : int;
      mutable closed : bool;
      closed_promise : unit Fut.Promise.t;
      mutable recv_promise : unit Fut.Promise.t;
      fast_send_promise : unit Fut.Promise.t;
    }

    let create ?(fast_count = 0) () =
      let open Fut.Infix_monad in
      let fast_send_promise = Fut.Promise.create () in
      Fut.Promise.set fast_send_promise ()
      >>| fun () ->
      {
        queue = Queue.create ();
        fast_count;
        closed = false;
        closed_promise = Fut.Promise.create ();
        recv_promise = Fut.Promise.create ();
        fast_send_promise;
      }

    let compute_send_promise fast_count len fast_send_promise =
      if len >= fast_count then
        Fut.Promise.create ()
      else
        fast_send_promise

    let replace_recv_promise_if_aborted t =
      match Fut.state (Fut.Promise.future t.recv_promise) with
        | `Aborted                 -> t.recv_promise <- Fut.Promise.create ()
        | `Undet | `Exn _ | `Det _ -> ()

    let send t msg =
      let open Fut.Infix_monad in
      if t.closed then
        Fut.return `Closed
      else if Queue.is_empty t.queue then (
        let promise =
          compute_send_promise t.fast_count (Queue.length t.queue) t.fast_send_promise
        in
        Queue.add (msg, promise) t.queue;
        (* Ordering matters here because when setting a recv_promise, all
           actions on it are executed immediately and it could be that the code
           goes to wait again.  The [recv] code waits on [t.recv_promise] if the
           queue is empty, but since the promise is already determined it would
           execute immediately and hit the [assert false].  So the promise is
           saved, then replaced, before setting it so any new calls to [recv]
           will wait for the next receive. *)
        replace_recv_promise_if_aborted t;
        let recv_promise = t.recv_promise in
        t.recv_promise <- Fut.Promise.create ();
        Fut.Promise.set recv_promise () >>= fun () -> Fut.Promise.future promise >>| fun v -> `Ok v
      ) else
        let promise =
          compute_send_promise t.fast_count (Queue.length t.queue) t.fast_send_promise
        in
        Queue.add (msg, promise) t.queue;
        Fut.Promise.future promise >>| fun v -> `Ok v

    let recv t =
      let open Fut.Infix_monad in
      if Queue.is_empty t.queue && t.closed then
        Fut.return `Closed
      else if not (Queue.is_empty t.queue) then
        let (msg, promise) = Queue.pop t.queue in
        Fut.Promise.set promise () >>| fun () -> `Ok msg
      else (
        replace_recv_promise_if_aborted t;
        Fut.Promise.future t.recv_promise
        >>= fun () ->
        if Queue.is_empty t.queue && t.closed then
          Fut.return `Closed
        else if Queue.is_empty t.queue then
          assert false
        else
          let (msg, promise) = Queue.pop t.queue in
          Fut.Promise.set promise () >>| fun () -> `Ok msg
      )

    let close t =
      let open Fut.Infix_monad in
      t.closed <- true;
      Fut.Promise.set t.closed_promise ()
      >>= fun () -> Fut.Promise.set t.recv_promise () >>| fun () -> ()

    let close_with_abort t =
      let open Fut.Infix_monad in
      t.closed <- true;
      Fut.Promise.set t.closed_promise ()
      >>= fun () ->
      Fut.Promise.set t.recv_promise ()
      >>= fun () ->
      let rec abort_until_empty () =
        if not (Queue.is_empty t.queue) then
          let (_, promise) = Queue.pop t.queue in
          Fut.abort (Fut.Promise.future promise) >>= fun () -> abort_until_empty ()
        else
          Fut.return ()
      in
      abort_until_empty () >>| fun () -> ()

    let closed t =
      let open Fut.Infix_monad in
      let promise = Fut.Promise.create () in
      Fut.fork
        (Fut.await_map
           (function
             | `Det ()  -> Fut.Promise.set promise ()
             | `Exn exn -> Fut.Promise.set_exn promise exn
             | `Aborted -> Fut.abort (Fut.Promise.future promise))
           (Fut.Promise.future t.closed_promise))
      >>= fun () -> Fut.Promise.future promise
  end

  module type S = module type of T

  module type Msg = sig
    type t
  end

  module Channel (Q : S) (Msg : Msg) :
    Abb_channel_intf.Make(Fut).S with type t = Msg.t Q.t and type msg = Msg.t = struct
    type msg = Msg.t

    type t = msg Q.t

    let send = Q.send

    let recv = Q.recv

    let close = Q.close

    let close_with_abort = Q.close_with_abort

    let closed = Q.closed
  end

  module Abbc = Abb_channel.Make (Fut)

  type 'a reader = (Abbc.reader, 'a) Abbc.t

  type 'a writer = (Abbc.writer, 'a) Abbc.t

  let to_abb_channel (type m) (t : m T.t) =
    let module Msg : Msg with type t = m = struct
      type t = m
    end in
    let module Chan = Channel (T) (Msg) in
    Abbc.create (module Chan) (t : m T.t)
end
