module Make (Abb : Abb_intf.S) = struct
  module Oth_abb = Oth_abb.Make (Abb)
  module Fut_comb = Abb_future_combinators.Make (Abb.Future)

  (* Marker exception for the loop-stopper regression test below. *)
  exception Boom

  (* Future-state comparisons here only ever check the state tag
     ([`Undet]/[`Aborted]); no [`Det] value is present, so its eq/pp
     are placeholders. *)
  let assert_state expected actual =
    Oth.Assert.eq
      ~eq:(Abb_intf.Future.State.equal (fun _ _ -> false))
      ~pp:(Abb_intf.Future.State.pp (fun fmt _ -> Format.pp_print_string fmt "<det>"))
      expected
      actual

  let thread_run_test =
    Oth_abb.test ~desc:"Simple increment in thread" ~name:"Thread run" (fun () ->
        let open Abb.Future.Infix_monad in
        let n = Random.int 10 in
        Abb.Thread.run (fun () -> n + 1)
        >>| fun n' -> Oth.Assert.Eq.int ~expected:(n + 1) ~actual:n')

  let double_abort_test =
    Oth_abb.test ~name:"Double abort" (fun () ->
        let open Abb.Future.Infix_monad in
        (* Start two threads that just sleep *)
        Abb.Future.fork (Abb.Thread.run (fun () -> Unix.sleepf 0.5))
        >>= fun fut_1 ->
        Abb.Future.fork (Abb.Thread.run (fun () -> Unix.sleepf 0.5))
        >>= fun fut_2 ->
        (* Wait for them to finish, this way we're guaranteed that both will
           have pending events. *)
        Unix.sleep 1;
        (* Take the first one that is finished and abort the other.  This way we
           know that the other event will be handled. *)
        Fut_comb.first fut_1 fut_2
        >>= fun ((), other) ->
        Abb.Future.abort other
        >>| fun () ->
        Oth.Assert.true_
          "one of the two futures was aborted"
          (Abb.Future.state fut_1 = `Aborted || Abb.Future.state fut_2 = `Aborted))

  (* Pool size 1: the lone worker is busy running a long [Unix.sleepf]
     when a second [Thread.run] is submitted.  The second thunk sits
     in the pool's queue.  Aborting the second future flips the op's
     [aborted] atomic; when the worker eventually pops the thunk it
     reads the flag and silently skips, so the body's side-effect
     never fires. *)
  let abort_while_queued =
    Oth.test ~name:"Thread.run: abort while queued never runs the body" (fun _state ->
        match
          (* [Scheduler.run_with_state] clamps the pool to at least 2
             workers, so saturate both with sleeping bodies before
             submitting the victim. *)
          Abb.Scheduler.run_with_state ~thread_pool_size:2 (fun () ->
              let open Abb.Future.Infix_monad in
              let ran_queued = Atomic.make false in
              let started = Atomic.make 0 in
              (* Each blocker signals when it is actually running, so we wait
                 on real worker occupancy rather than a fixed dispatch delay
                 (which the slow 2-vCPU macOS runner does not honour).  The
                 sleep only has to outlast the synchronized submit+abort. *)
              let blocker () =
                Atomic.incr started;
                Unix.sleepf 0.5
              in
              Abb.Future.fork (Abb.Thread.run blocker)
              >>= fun blocker_a ->
              Abb.Future.fork (Abb.Thread.run blocker)
              >>= fun blocker_b ->
              let rec wait_busy n =
                if Atomic.get started >= 2 then Abb.Future.return ()
                else if n <= 0 then Oth.Assert.false_ "blockers never occupied both workers"
                else Abb.Sys.sleep 0.005 >>= fun () -> wait_busy (n - 1)
              in
              wait_busy 400
              >>= fun () ->
              (* Both workers are confirmed busy, so this thunk is provably
                 sitting in the pool queue when we abort it. *)
              Abb.Future.fork (Abb.Thread.run (fun () -> Atomic.set ran_queued true))
              >>= fun queued ->
              Abb.Future.abort queued
              >>= fun () ->
              assert_state `Aborted (Abb.Future.state queued);
              (* A sentinel enqueued AFTER the victim: the queue is FIFO, so
                 when the sentinel runs a worker has already popped past the
                 victim and skipped it (it is aborted).  Awaiting the sentinel
                 settles [ran_queued] with no timing guess. *)
              Abb.Future.fork (Abb.Thread.run (fun () -> ()))
              >>= fun sentinel ->
              blocker_a
              >>= fun () ->
              blocker_b
              >>= fun () ->
              sentinel
              >>| fun () ->
              Oth.Assert.true_ "queued thread body never ran" (not (Atomic.get ran_queued)))
        with
        | `Det () -> ()
        | `Aborted -> Oth.Assert.false_ "scheduler run unexpectedly aborted"
        | `Exn (exn, Some bt) -> Printexc.raise_with_backtrace exn bt
        | `Exn (exn, None) -> raise exn)

  (* A thread that has already started cannot be stopped.  Submit a
     long-running body that flips a flag on entry, wait until we know
     it has started, then abort.  The body runs to completion and
     [ran] ends up [true]; the future still transitions to [`Aborted]
     and the result is suppressed. *)
  let abort_while_running =
    Oth.test
      ~name:"Thread.run: abort while running suppresses result, body still runs"
      (fun _state ->
        match
          Abb.Scheduler.run_with_state (fun () ->
              let open Abb.Future.Infix_monad in
              let started = Atomic.make false in
              let ran = Atomic.make false in
              Abb.Future.fork
                (Abb.Thread.run (fun () ->
                     Atomic.set started true;
                     Unix.sleepf 0.2;
                     Atomic.set ran true;
                     42))
              >>= fun fut ->
              let rec wait_started () =
                if Atomic.get started then Abb.Future.return ()
                else Abb.Sys.sleep 0.005 >>= wait_started
              in
              wait_started ()
              >>= fun () ->
              Abb.Future.abort fut
              >>= fun () ->
              assert_state `Aborted (Abb.Future.state fut);
              (* The body cannot be stopped once started, so it WILL set
                 [ran] — but on a slow / contended runner (e.g. the 2-vCPU
                 macOS CI) it can lag well past any fixed slack, so poll for
                 it rather than assume a deadline. *)
              let rec wait_ran n =
                if Atomic.get ran then Abb.Future.return ()
                else if n <= 0 then
                  Oth.Assert.false_ "already-started thread body never ran to completion"
                else Abb.Sys.sleep 0.02 >>= fun () -> wait_ran (n - 1)
              in
              wait_ran 250)
        with
        | `Det () -> ()
        | `Aborted -> Oth.Assert.false_ "scheduler run unexpectedly aborted"
        | `Exn (exn, Some bt) -> Printexc.raise_with_backtrace exn bt
        | `Exn (exn, None) -> raise exn)

  (* Regression for the macOS CI deadlock.  When the root future of a
     [Scheduler.run] resolves to [`Exn] (a raised exception / failed
     assertion) or [`Aborted] *after* it has suspended on an async op,
     [run]'s loop-stopper must still fire and stop the loop.  A plain
     [ret >>= fun _ -> stop] fires only on [`Det], so an exn/abort outcome
     used to leave [Luv.Loop.run] spinning forever — a deterministic,
     platform-independent hang (it only surfaced on macOS because that is
     where the abort/timing tests actually failed and produced an [`Exn]).
     These deadlock without the fix and return promptly with it. *)
  let exn_after_suspend_stops_loop =
    Oth.test ~name:"Run: exn outcome after suspend stops the loop" (fun _state ->
        match
          Abb.Scheduler.run_with_state (fun () ->
              let open Abb.Future.Infix_monad in
              Abb.Sys.sleep 0.01 >>= fun () -> raise Boom)
        with
        | `Exn (Boom, _) -> ()
        | `Det _ -> Oth.Assert.false_ "expected the exception to propagate out of run"
        | `Aborted -> Oth.Assert.false_ "expected `Exn, got `Aborted"
        | `Exn (exn, Some bt) -> Printexc.raise_with_backtrace exn bt
        | `Exn (exn, None) -> raise exn)

  let abort_after_suspend_stops_loop =
    Oth.test ~name:"Run: aborted outcome after suspend stops the loop" (fun _state ->
        match
          Abb.Scheduler.run_with_state (fun () ->
              let open Abb.Future.Infix_monad in
              Abb.Sys.sleep 0.01
              >>= fun () ->
              let blocker = Abb.Future.fork (Abb.Sys.sleep 100.0) in
              blocker
              >>= fun b -> Abb.Future.abort b >>= fun () -> b >>= fun () -> Abb.Future.return ())
        with
        | `Aborted -> ()
        | `Det _ -> Oth.Assert.false_ "expected the abort to propagate out of run"
        | `Exn (exn, Some bt) -> Printexc.raise_with_backtrace exn bt
        | `Exn (exn, None) -> raise exn)

  let test =
    Oth_abb.serial
      [
        thread_run_test;
        double_abort_test;
        abort_while_queued;
        abort_while_running;
        exn_after_suspend_stops_loop;
        abort_after_suspend_stops_loop;
      ]
end
