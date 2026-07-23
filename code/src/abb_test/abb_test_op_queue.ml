module Make (Abb : Abb_intf.S) = struct
  module Oth_abb = Oth_abb.Make (Abb)
  module Fut_comb = Abb_future_combinators.Make (Abb.Future)

  (* Future-state comparisons here only ever check the state tag
     ([`Undet]/[`Aborted]); no [`Det] value is present, so its eq/pp
     are placeholders. *)
  let assert_state expected actual =
    Oth.Assert.eq
      ~eq:(Abb_intf.Future.State.equal (fun _ _ -> false))
      ~pp:(Abb_intf.Future.State.pp (fun fmt _ -> Format.pp_print_string fmt "<det>"))
      expected
      actual

  (* Abort a sleep before its op has had a chance to dispatch.  We create
     the sleep future then immediately abort it, before the scheduler ticks
     the op queue.  The dispatcher must see [aborted = true] and skip the
     [Luv.Timer.init], leaving no handle behind. *)
  let abort_before_dispatch =
    Oth_abb.test ~name:"Op_queue: sleep abort before dispatch" (fun () ->
        let open Abb.Future.Infix_monad in
        Abb.Future.fork (Abb.Sys.sleep 5.0)
        >>= fun sleep_fut ->
        Abb.Future.abort sleep_fut
        >>= fun () ->
        assert_state `Aborted (Abb.Future.state sleep_fut);
        Abb.Future.return ())

  (* Abort a sleep that is already live in libuv: we wait briefly so the
     dispatcher has run and the timer is armed, then abort.  The abort
     closure must stop+close the timer and the future must transition to
     Aborted; the timer must not fire after that. *)
  let abort_after_start =
    Oth_abb.test ~name:"Op_queue: sleep abort after start" (fun () ->
        let open Abb.Future.Infix_monad in
        Abb.Future.fork (Abb.Sys.sleep 5.0)
        >>= fun sleep_fut ->
        Abb.Sys.sleep 0.05
        >>= fun () ->
        Abb.Future.abort sleep_fut
        >>= fun () ->
        assert_state `Aborted (Abb.Future.state sleep_fut);
        (* Sleep past when the original sleep would have fired to confirm
           the timer was actually torn down.  If it had fired, the abort
           closure could have raced with the on_fire path; after this
           extra wait we should still have [`Aborted]. *)
        Abb.Sys.sleep 0.1
        >>= fun () ->
        assert_state `Aborted (Abb.Future.state sleep_fut);
        Abb.Future.return ())

  (* Many concurrent sleeps stress the queue + dispatcher.  All must
     resolve. *)
  let many_concurrent_sleeps =
    Oth_abb.test ~name:"Op_queue: many concurrent sleeps" (fun () ->
        let open Abb.Future.Infix_monad in
        let n = 200 in
        Fut_comb.List.iter_par ~f:(fun _ -> Abb.Sys.sleep 0.05) (CCList.init n (fun i -> i))
        >>= fun () -> Abb.Future.return ())

  (* Abort half of a batch mid-flight.  Confirms the dispatcher's per-op
     [aborted] flag is independent across ops. *)
  let abort_half_of_batch =
    Oth_abb.test ~name:"Op_queue: abort half of a sleep batch" (fun () ->
        let open Abb.Future.Infix_monad in
        let n = 50 in
        let make_one _ = Abb.Future.fork (Abb.Sys.sleep 5.0) in
        Fut_comb.List.map ~f:make_one (CCList.init n (fun i -> i))
        >>= fun futs ->
        (* Abort the even-indexed ones. *)
        Fut_comb.List.iter
          ~f:(fun (i, fut) -> if i mod 2 = 0 then Abb.Future.abort fut else Abb.Future.return ())
          (CCList.mapi (fun i fut -> (i, fut)) futs)
        >>= fun () ->
        CCList.iteri
          (fun i fut ->
            if i mod 2 = 0 then assert_state `Aborted (Abb.Future.state fut)
            else assert_state `Undet (Abb.Future.state fut))
          futs;
        (* Abort the rest so we don't leave futures hanging at scheduler
           shutdown. *)
        Fut_comb.List.iter
          ~f:(fun (i, fut) -> if i mod 2 <> 0 then Abb.Future.abort fut else Abb.Future.return ())
          (CCList.mapi (fun i fut -> (i, fut)) futs)
        >>= fun () -> Abb.Future.return ())

  let test =
    Oth_abb.serial
      [ abort_before_dispatch; abort_after_start; many_concurrent_sleeps; abort_half_of_batch ]
end
