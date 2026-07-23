module Make (S : Abb_intf.S) = struct
  module Fc = Abb_future_combinators.Make (S.Future)

  type 'a t = 'a S.Chan.t

  let run f chan =
    let open S.Future.Infix_monad in
    Fc.with_finally
      (fun () -> S.Future.await (f chan) >>= fun _ -> S.Future.return ())
      ~finally:(fun () ->
        S.Chan.close chan;
        S.Future.return ())

  let create ?(capacity = 100) ?name ?(pinned = true) f =
    let open S.Future.Infix_monad in
    let chan = S.Chan.create ~capacity () in
    S.Task.run ?name ~pinned (fun () -> run f chan) >>| fun _ -> chan

  module Request = struct
    type ('req, 'resp) t = {
      payload : 'req;
      reply : 'resp Abb_intf.Future.Set.t S.Chan.t;
      (* Cap-1 chan that the caller's [finally] closes when it tears down
         the call (either normal completion or abort).  [respond] watches
         its closure as the caller-abort signal: when it fires before the
         worker finishes, [respond] aborts the worker future.  Using a
         [Chan] rather than a shared [Promise] keeps the cross-task
         communication on the primitive this module's whole API is built
         around. *)
      caller_alive : unit S.Chan.t;
    }

    let payload t = t.payload
    let reply_chan t = t.reply
    let caller_alive t = t.caller_alive
    let create payload reply caller_alive = { payload; reply; caller_alive }
  end

  let notify chan msg = S.Chan.send chan msg

  let call chan wrap req =
    let open S.Future.Infix_monad in
    let reply = S.Chan.create ~capacity:1 () in
    let caller_alive = S.Chan.create ~capacity:1 () in
    let request = Request.create req reply caller_alive in
    Fc.protect_finally
      ~setup:(fun () ->
        S.Chan.send chan (wrap request)
        >>= function
        | Ok () -> S.Future.return (Ok ())
        | Error `Chan_closed -> S.Future.return (Error `Chan_closed))
      ~finally:(fun _ ->
        S.Chan.close reply;
        S.Chan.close caller_alive;
        S.Future.return ())
      (function
        | Error `Chan_closed -> S.Future.return (Error `Chan_closed)
        | Ok () -> (
            S.Chan.recv reply
            >>= function
            | Ok (`Det v) -> S.Future.return (Ok v)
            | Ok (`Exn (e, bt)) ->
                let p = S.Future.Promise.create () in
                S.Future.Promise.set_exn p (e, bt) >>= fun () -> S.Future.Promise.future p
            | Ok `Aborted ->
                let p = S.Future.Promise.create () in
                let fut = S.Future.Promise.future p in
                S.Future.abort fut >>= fun () -> fut
            | Error `Chan_closed -> S.Future.return (Error `Chan_closed)))

  let respond req f =
    let open S.Future.Infix_monad in
    (* Worker future, with exception capture wrapped in.  Forked so we
       can race it against the caller-alive signal and abort it on
       caller-side teardown. *)
    S.Future.fork
      (try S.Future.await (f ())
       with exn ->
         let bt = Printexc.get_raw_backtrace () in
         S.Future.return (`Exn (exn, Some bt)))
    >>= fun worker_fut ->
    let work_tagged = worker_fut >>| fun wire -> `Done wire in
    let caller_tagged = S.Chan.recv (Request.caller_alive req) >>| fun _ -> `Caller_done in
    Fc.first work_tagged caller_tagged
    >>= fun (winner, loser) ->
    S.Future.abort loser
    >>= fun () ->
    match winner with
    | `Done wire -> (
        S.Chan.send (Request.reply_chan req) wire
        >>= function
        | Ok () | Error `Chan_closed -> S.Future.return ())
    | `Caller_done ->
        (* Caller tore down its call: the reply chan is closed and the
           response would be dropped, so abort the still-running worker
           and return.  Aborting [worker_fut] propagates abort into [f]'s
           own chain. *)
        S.Future.abort worker_fut

  module type REQ = sig
    type 'resp t
  end

  module Make_typed (R : REQ) = struct
    type msg = Msg : ('resp R.t, 'resp) Request.t -> msg
    type svc = msg t

    let call_typed (chan : svc) (req : 'resp R.t) : ('resp, [> `Chan_closed ]) result S.Future.t =
      call chan (fun r -> Msg r) req

    let call = call_typed

    let create ?capacity ?name ?pinned (f : svc -> unit S.Future.t) : svc S.Future.t =
      create ?capacity ?name ?pinned f
  end
end
