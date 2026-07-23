module Abb = Abb_scheduler_select
module Oth_abb = Oth_abb.Make (Abb)
module Fut = Abb.Future
module Akce = Abb_keyed_concurrent_executor.Make (Abb) (CCString)

(* These tests exercise the Chan-based keyed concurrent executor against the
   real [Abb_scheduler_select] scheduler. The executor runs its server on a
   separate task, so we cannot synchronously step the scheduler and inspect
   intermediate states the way the old [Abb_fut] tests did. Instead we sequence
   work with rendezvous promises and use [drain_and_destroy] to deterministically
   await completion before asserting. *)

(* Work that simply records that it ran by setting [p]. *)
let record p () = Fut.Promise.set p ()

let test_work_runs =
  Oth_abb.test ~name:"Work enqueued runs" (fun () ->
      let open Fut.Infix_monad in
      let ran = Fut.Promise.create () in
      Akce.create ~slots:10 (fun f -> f ())
      >>= fun executor ->
      Akce.enqueue executor ~keys:[ "a" ] (record ran)
      >>= fun res ->
      assert (res = Ok ());
      Akce.drain_and_destroy executor
      >>= fun () ->
      (* drain_and_destroy returns only once all enqueued work has completed. *)
      assert (Fut.state (Fut.Promise.future ran) = `Det ());
      Fut.return ())

let test_non_overlapping_keys =
  Oth_abb.test ~name:"Non overlapping keys both run" (fun () ->
      let open Fut.Infix_monad in
      let ran1 = Fut.Promise.create () in
      let ran2 = Fut.Promise.create () in
      Akce.create ~slots:10 (fun f -> f ())
      >>= fun executor ->
      Akce.enqueue executor ~keys:[ "a" ] (record ran1)
      >>= fun res1 ->
      assert (res1 = Ok ());
      Akce.enqueue executor ~keys:[ "b" ] (record ran2)
      >>= fun res2 ->
      assert (res2 = Ok ());
      Akce.drain_and_destroy executor
      >>= fun () ->
      assert (Fut.state (Fut.Promise.future ran1) = `Det ());
      assert (Fut.state (Fut.Promise.future ran2) = `Det ());
      Fut.return ())

let test_overlapping_keys_serialize =
  Oth_abb.test ~name:"Overlapping keys serialize" (fun () ->
      let open Fut.Infix_monad in
      (* Both items share key "a", so the second can only start after the first
         has fully finished. We record start/finish events into a buffer. Even
         though the first item yields (via sleep), the lock on "a" guarantees the
         second cannot interleave, so the recorded order is deterministic. *)
      let events = ref [] in
      let push e = events := e :: !events in
      let work label () =
        push (label ^ "-start");
        Abb.Sys.sleep 0.0
        >>= fun () ->
        push (label ^ "-end");
        Fut.return ()
      in
      Akce.create ~slots:10 (fun f -> f ())
      >>= fun executor ->
      Akce.enqueue executor ~keys:[ "a" ] (work "1")
      >>= fun _ ->
      Akce.enqueue executor ~keys:[ "a" ] (work "2")
      >>= fun _ ->
      Akce.drain_and_destroy executor
      >>= fun () ->
      assert (List.rev !events = [ "1-start"; "1-end"; "2-start"; "2-end" ]);
      Fut.return ())

let test_drain_waits_for_completion =
  Oth_abb.test ~name:"drain_and_destroy waits for completion" (fun () ->
      let open Fut.Infix_monad in
      (* The work only completes once [gate] is set. We arrange for [gate] to be
         set from within the work itself after a yield, so that [drain_and_destroy]
         genuinely has to wait for in-flight work rather than returning early. *)
      let started = Fut.Promise.create () in
      let finished = Fut.Promise.create () in
      let work () =
        Fut.Promise.set started ()
        >>= fun () -> Abb.Sys.sleep 0.0 >>= fun () -> Fut.Promise.set finished ()
      in
      Akce.create ~slots:10 (fun f -> f ())
      >>= fun executor ->
      Akce.enqueue executor ~keys:[ "a" ] work
      >>= fun _ ->
      Akce.drain_and_destroy executor
      >>= fun () ->
      assert (Fut.state (Fut.Promise.future started) = `Det ());
      assert (Fut.state (Fut.Promise.future finished) = `Det ());
      Fut.return ())

let test_empty_key_list =
  Oth_abb.test ~name:"Empty key list works" (fun () ->
      let open Fut.Infix_monad in
      (* Empty key lists do not block on any other key, including other empty key
         lists, so both items can run and both must complete. *)
      let ran1 = Fut.Promise.create () in
      let ran2 = Fut.Promise.create () in
      Akce.create ~slots:10 (fun f -> f ())
      >>= fun executor ->
      Akce.enqueue executor ~keys:[] (record ran1)
      >>= fun res1 ->
      assert (res1 = Ok ());
      Akce.enqueue executor ~keys:[] (record ran2)
      >>= fun res2 ->
      assert (res2 = Ok ());
      Akce.drain_and_destroy executor
      >>= fun () ->
      assert (Fut.state (Fut.Promise.future ran1) = `Det ());
      assert (Fut.state (Fut.Promise.future ran2) = `Det ());
      Fut.return ())

let test_enqueue_after_drain_closed =
  Oth_abb.test ~name:"Enqueue after drain is closed" (fun () ->
      let open Fut.Infix_monad in
      Akce.create ~slots:10 (fun f -> f ())
      >>= fun executor ->
      Akce.drain_and_destroy executor
      >>= fun () ->
      Akce.enqueue executor ~keys:[ "a" ] (fun () -> Fut.return ())
      >>= fun res ->
      assert (res = Error `Closed);
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
             test_non_overlapping_keys;
             test_overlapping_keys_serialize;
             test_drain_waits_for_completion;
             test_empty_key_list;
             test_enqueue_after_drain_closed;
           ]))
