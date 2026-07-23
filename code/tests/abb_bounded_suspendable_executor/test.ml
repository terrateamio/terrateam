module Abb = Abb_scheduler_select
module Oth_abb = Oth_abb.Make (Abb)
module Fut = Abb.Future
module Fc = Abb_future_combinators.Make (Fut)
module Exec = Abb_bounded_suspendable_executor.Make (Abb) (CCString)

(* These tests exercise the Chan-based bounded suspendable executor against the
   real [Abb_scheduler_select] scheduler. The executor server runs on a separate
   task, so we sequence work with rendezvous promises and await the [run] futures
   (which resolve when the work completes) rather than synchronously stepping the
   scheduler as the old [Abb_fut] tests did. *)

let test_work_runs =
  Oth_abb.test ~name:"Work runs and returns its result" (fun () ->
      let open Fut.Infix_monad in
      Exec.create ~slots:10 ()
      >>= fun executor ->
      Exec.run executor ~name:[ "task" ] (fun () -> Fut.return 42)
      >>= fun result ->
      assert (result = 42);
      Fut.return ())

let test_slots_bound_concurrency =
  Oth_abb.test ~name:"Slots bound concurrency" (fun () ->
      let open Fut.Infix_monad in
      (* With a single slot, at most one task body may be in flight at a time.
         Each body bumps a live counter and records the peak. The scheduler is
         single-domain, so the counter is safe to mutate from the bodies. Each
         body yields between bump and unbump so that a broken bound would let two
         bodies overlap and push the peak above 1. *)
      let running = ref 0 in
      let peak = ref 0 in
      let body () =
        incr running;
        peak := max !peak !running;
        Abb.Sys.sleep 0.0
        >>= fun () ->
        decr running;
        Fut.return ()
      in
      Exec.create ~slots:1 ()
      >>= fun executor ->
      Fut.fork (Exec.run executor ~name:[ "task1" ] body)
      >>= fun t1 ->
      Fut.fork (Exec.run executor ~name:[ "task2" ] body)
      >>= fun t2 ->
      Fut.fork (Exec.run executor ~name:[ "task3" ] body)
      >>= fun t3 ->
      Fc.all [ t1; t2; t3 ]
      >>= fun _ ->
      assert (!peak = 1);
      assert (!running = 0);
      Fut.return ())

let test_slots_allow_concurrency =
  Oth_abb.test ~name:"Multiple slots allow concurrency" (fun () ->
      let open Fut.Infix_monad in
      (* With two slots, two tasks can be in flight simultaneously. Each task
         signals it has started and then waits on a shared gate. If both can
         start before the gate is released, the slots genuinely allowed
         concurrency. *)
      let started1 = Fut.Promise.create () in
      let started2 = Fut.Promise.create () in
      let gate = Fut.Promise.create () in
      let make_body started () = Fut.Promise.set started () >>= fun () -> Fut.Promise.future gate in
      Exec.create ~slots:2 ()
      >>= fun executor ->
      Fut.fork (Exec.run executor ~name:[ "task1" ] (make_body started1))
      >>= fun t1 ->
      Fut.fork (Exec.run executor ~name:[ "task2" ] (make_body started2))
      >>= fun t2 ->
      (* Both tasks must be able to start while the gate is still closed. *)
      Fut.Promise.future started1
      >>= fun () ->
      Fut.Promise.future started2
      >>= fun () ->
      Fut.Promise.set gate () >>= fun () -> Fc.all [ t1; t2 ] >>= fun _ -> Fut.return ())

let test_suspend_unsuspend =
  Oth_abb.test ~name:"Suspend frees a slot, unsuspend restores it" (fun () ->
      let open Fut.Infix_monad in
      (* Single slot. Task A occupies it and blocks on [a_gate]. Suspending A
         removes it from the running set (freeing the slot) even though its body
         is still in flight, allowing B to be scheduled into the freed slot. B
         runs to completion. Then we unsuspend A and release its gate so A
         completes too. *)
      let a_started = Fut.Promise.create () in
      let a_gate = Fut.Promise.create () in
      let b_started = Fut.Promise.create () in
      let b_gate = Fut.Promise.create () in
      Exec.create ~slots:1 ()
      >>= fun executor ->
      Fut.fork
        (Exec.run executor ~name:[ "A" ] (fun () ->
             Fut.Promise.set a_started () >>= fun () -> Fut.Promise.future a_gate))
      >>= fun task_a ->
      (* Wait until A is actually running and holding the only slot. *)
      Fut.Promise.future a_started
      >>= fun () ->
      (* Suspend A; this frees the slot without finishing A's body. *)
      Exec.suspend executor ~name:[ "A" ]
      >>= fun () ->
      (* B can now be scheduled into the freed slot and run to completion. *)
      Fut.fork
        (Exec.run executor ~name:[ "B" ] (fun () ->
             Fut.Promise.set b_started () >>= fun () -> Fut.Promise.future b_gate))
      >>= fun task_b ->
      Fut.Promise.future b_started
      >>= fun () ->
      Fut.Promise.set b_gate ()
      >>= fun () ->
      task_b
      >>= fun () ->
      (* Unsuspend A and let it finish. *)
      Exec.unsuspend executor ~name:[ "A" ]
      >>= fun () ->
      Fut.Promise.set a_gate ()
      >>= fun () ->
      task_a
      >>= fun () ->
      assert (Fut.state task_a = `Det ());
      assert (Fut.state task_b = `Det ());
      Fut.return ())

let () =
  Random.self_init ();
  Oth.run
    ~file:__FILE__
    Oth_abb.(
      to_sync_test
        (serial
           [
             test_work_runs;
             test_slots_bound_concurrency;
             test_slots_allow_concurrency;
             test_suspend_unsuspend;
           ]))
