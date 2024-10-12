module Fut = Abb_fut.Make (struct
  type t = unit
end)

module Akce = Abb_keyed_concurrent_executor.Make (Fut) (CCString)

let dummy_state = Abb_fut.State.create ()

let test_simple =
  Oth.test ~name:"Simple" (fun _ ->
      let trigger = Fut.Promise.create () in
      let finished = Fut.Promise.create () in
      let run =
        let open Fut.Infix_monad in
        Akce.create ~slots:10 (fun f -> f ())
        >>= fun executor ->
        Akce.enqueue executor ~keys:[ "test" ] (fun () ->
            Fut.Promise.future trigger >>= fun () -> Fut.Promise.set finished ())
        >>= fun _ -> Akce.destroy executor
      in
      ignore (Fut.run_with_state run dummy_state);
      assert (Fut.state (Fut.Promise.future finished) = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set trigger ()) dummy_state);
      assert (Fut.state (Fut.Promise.future finished) = `Det ());
      assert (Fut.state run = `Det ()))

let test_non_overlapping_keys =
  Oth.test ~name:"Non Overlapping Keys" (fun _ ->
      let rendevous_test1 = Fut.Promise.create () in
      let trigger_test1 = Fut.Promise.create () in
      let finished_test1 = Fut.Promise.create () in
      let rendevous_test2 = Fut.Promise.create () in
      let trigger_test2 = Fut.Promise.create () in
      let finished_test2 = Fut.Promise.create () in
      let run =
        let open Fut.Infix_monad in
        Akce.create ~slots:10 (fun f -> f ())
        >>= fun executor ->
        Akce.enqueue executor ~keys:[ "test1" ] (fun () ->
            Fut.Promise.set rendevous_test1 ()
            >>= fun () ->
            Fut.Promise.future trigger_test1 >>= fun () -> Fut.Promise.set finished_test1 ())
        >>= fun _ ->
        Akce.enqueue executor ~keys:[ "test2" ] (fun () ->
            Fut.Promise.set rendevous_test2 ()
            >>= fun () ->
            Fut.Promise.future trigger_test2 >>= fun () -> Fut.Promise.set finished_test2 ())
        >>= fun _ -> Akce.destroy executor
      in
      ignore (Fut.run_with_state run dummy_state);
      assert (Fut.state (Fut.Promise.future finished_test1) = `Undet);
      assert (Fut.state (Fut.Promise.future finished_test2) = `Undet);
      assert (Fut.state (Fut.Promise.future rendevous_test1) = `Det ());
      assert (Fut.state (Fut.Promise.future rendevous_test2) = `Det ());
      ignore (Fut.run_with_state (Fut.Promise.set trigger_test1 ()) dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set trigger_test2 ()) dummy_state);
      assert (Fut.state (Fut.Promise.future finished_test1) = `Det ());
      assert (Fut.state (Fut.Promise.future finished_test2) = `Det ());
      assert (Fut.state run = `Det ()))

let test_overlapping_keys =
  Oth.test ~name:"Overlapping Keys" (fun _ ->
      let rendevous_test1 = Fut.Promise.create () in
      let trigger_test1 = Fut.Promise.create () in
      let finished_test1 = Fut.Promise.create () in
      let rendevous_test2 = Fut.Promise.create () in
      let trigger_test2 = Fut.Promise.create () in
      let finished_test2 = Fut.Promise.create () in
      let run =
        let open Fut.Infix_monad in
        Akce.create ~slots:10 (fun f -> f ())
        >>= fun executor ->
        Akce.enqueue executor ~keys:[ "test1" ] (fun () ->
            Fut.Promise.set rendevous_test1 ()
            >>= fun () ->
            Fut.Promise.future trigger_test1 >>= fun () -> Fut.Promise.set finished_test1 ())
        >>= fun _ ->
        Akce.enqueue executor ~keys:[ "test1" ] (fun () ->
            Fut.Promise.set rendevous_test2 ()
            >>= fun () ->
            Fut.Promise.future trigger_test2 >>= fun () -> Fut.Promise.set finished_test2 ())
        >>= fun _ -> Akce.drain_and_destroy executor
      in
      ignore (Fut.run_with_state run dummy_state);
      assert (Fut.state (Fut.Promise.future finished_test1) = `Undet);
      assert (Fut.state (Fut.Promise.future finished_test2) = `Undet);
      assert (Fut.state (Fut.Promise.future rendevous_test1) = `Det ());
      assert (Fut.state (Fut.Promise.future rendevous_test2) = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set trigger_test1 ()) dummy_state);
      assert (Fut.state (Fut.Promise.future finished_test1) = `Det ());
      assert (Fut.state (Fut.Promise.future rendevous_test2) = `Det ());
      ignore (Fut.run_with_state (Fut.Promise.set trigger_test2 ()) dummy_state);
      assert (Fut.state (Fut.Promise.future finished_test2) = `Det ());
      assert (Fut.state run = `Det ()))

let test_multiple_drains_notified =
  Oth.test ~name:"Multiple drains notified" (fun _ ->
      let rendevous_test1 = Fut.Promise.create () in
      let trigger_test1 = Fut.Promise.create () in
      let finished_test1 = Fut.Promise.create () in
      let drained1 = Fut.Promise.create () in
      let drained2 = Fut.Promise.create () in
      let run =
        let open Fut.Infix_monad in
        Akce.create ~slots:10 (fun f -> f ())
        >>= fun executor ->
        Akce.enqueue executor ~keys:[ "test1" ] (fun () ->
            Fut.Promise.set rendevous_test1 ()
            >>= fun () ->
            Fut.Promise.future trigger_test1 >>= fun () -> Fut.Promise.set finished_test1 ())
        >>= fun _ ->
        Fut.fork (Akce.drain_and_destroy executor >>= fun () -> Fut.Promise.set drained1 ())
        >>= fun _ ->
        Fut.fork (Akce.drain_and_destroy executor >>= fun () -> Fut.Promise.set drained2 ())
        >>= fun _ -> Fut.return ()
      in
      ignore (Fut.run_with_state run dummy_state);
      assert (Fut.state (Fut.Promise.future finished_test1) = `Undet);
      assert (Fut.state (Fut.Promise.future rendevous_test1) = `Det ());
      assert (Fut.state (Fut.Promise.future drained1) = `Undet);
      assert (Fut.state (Fut.Promise.future drained2) = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set trigger_test1 ()) dummy_state);
      assert (Fut.state (Fut.Promise.future finished_test1) = `Det ());
      assert (Fut.state (Fut.Promise.future drained1) = `Det ());
      assert (Fut.state (Fut.Promise.future drained2) = `Det ());
      assert (Fut.state run = `Det ()))

let test_slot_count_respected =
  Oth.test ~name:"Slot count respected" (fun _ ->
      let rendevous_test1 = Fut.Promise.create () in
      let trigger_test1 = Fut.Promise.create () in
      let finished_test1 = Fut.Promise.create () in
      let rendevous_test2 = Fut.Promise.create () in
      let trigger_test2 = Fut.Promise.create () in
      let finished_test2 = Fut.Promise.create () in
      let run =
        let open Fut.Infix_monad in
        Akce.create ~slots:1 (fun f -> f ())
        >>= fun executor ->
        Akce.enqueue executor ~keys:[ "test1" ] (fun () ->
            Fut.Promise.set rendevous_test1 ()
            >>= fun () ->
            Fut.Promise.future trigger_test1 >>= fun () -> Fut.Promise.set finished_test1 ())
        >>= fun _ ->
        Akce.enqueue executor ~keys:[ "test2" ] (fun () ->
            Fut.Promise.set rendevous_test2 ()
            >>= fun () ->
            Fut.Promise.future trigger_test2 >>= fun () -> Fut.Promise.set finished_test2 ())
        >>= fun _ -> Akce.drain_and_destroy executor
      in
      ignore (Fut.run_with_state run dummy_state);
      assert (Fut.state (Fut.Promise.future finished_test1) = `Undet);
      assert (Fut.state (Fut.Promise.future finished_test2) = `Undet);
      assert (Fut.state (Fut.Promise.future rendevous_test1) = `Det ());
      assert (Fut.state (Fut.Promise.future rendevous_test2) = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set trigger_test1 ()) dummy_state);
      assert (Fut.state (Fut.Promise.future finished_test1) = `Det ());
      assert (Fut.state (Fut.Promise.future rendevous_test2) = `Det ());
      ignore (Fut.run_with_state (Fut.Promise.set trigger_test2 ()) dummy_state);
      assert (Fut.state (Fut.Promise.future finished_test2) = `Det ());
      assert (Fut.state run = `Det ()))

let test_would_lock_respected =
  Oth.test ~name:"Would lock respected" (fun _ ->
      let rendevous_test1 = Fut.Promise.create () in
      let trigger_test1 = Fut.Promise.create () in
      let finished_test1 = Fut.Promise.create () in
      let rendevous_test2 = Fut.Promise.create () in
      let trigger_test2 = Fut.Promise.create () in
      let finished_test2 = Fut.Promise.create () in
      let rendevous_test3 = Fut.Promise.create () in
      let trigger_test3 = Fut.Promise.create () in
      let finished_test3 = Fut.Promise.create () in
      let run =
        let open Fut.Infix_monad in
        Akce.create ~slots:1 (fun f -> f ())
        >>= fun executor ->
        Akce.enqueue executor ~keys:[ "A" ] (fun () ->
            Fut.Promise.set rendevous_test1 ()
            >>= fun () ->
            Fut.Promise.future trigger_test1 >>= fun () -> Fut.Promise.set finished_test1 ())
        >>= fun _ ->
        Akce.enqueue executor ~keys:[ "A"; "B" ] (fun () ->
            Fut.Promise.set rendevous_test2 ()
            >>= fun () ->
            Fut.Promise.future trigger_test2 >>= fun () -> Fut.Promise.set finished_test2 ())
        >>= fun _ ->
        Akce.enqueue executor ~keys:[ "B"; "C" ] (fun () ->
            Fut.Promise.set rendevous_test3 ()
            >>= fun () ->
            Fut.Promise.future trigger_test3 >>= fun () -> Fut.Promise.set finished_test3 ())
        >>= fun _ -> Akce.drain_and_destroy executor
      in
      ignore (Fut.run_with_state run dummy_state);
      assert (Fut.state (Fut.Promise.future finished_test1) = `Undet);
      assert (Fut.state (Fut.Promise.future finished_test2) = `Undet);
      assert (Fut.state (Fut.Promise.future finished_test3) = `Undet);
      assert (Fut.state (Fut.Promise.future rendevous_test1) = `Det ());
      assert (Fut.state (Fut.Promise.future rendevous_test2) = `Undet);
      assert (Fut.state (Fut.Promise.future rendevous_test3) = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set trigger_test1 ()) dummy_state);
      assert (Fut.state (Fut.Promise.future finished_test1) = `Det ());
      assert (Fut.state (Fut.Promise.future rendevous_test2) = `Det ());
      assert (Fut.state (Fut.Promise.future rendevous_test3) = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set trigger_test2 ()) dummy_state);
      assert (Fut.state (Fut.Promise.future finished_test2) = `Det ());
      assert (Fut.state (Fut.Promise.future rendevous_test3) = `Det ());
      ignore (Fut.run_with_state (Fut.Promise.set trigger_test3 ()) dummy_state);
      assert (Fut.state (Fut.Promise.future finished_test3) = `Det ());
      assert (Fut.state run = `Det ()))

let test_draining_does_not_enqueue_work =
  Oth.test ~name:"Draining does not enqueue work" (fun _ ->
      let rendevous_test1 = Fut.Promise.create () in
      let rendevous_test2 = Fut.Promise.create () in
      let trigger_test1 = Fut.Promise.create () in
      let finished_test1 = Fut.Promise.create () in
      let drained1 = Fut.Promise.create () in
      let run =
        let open Fut.Infix_monad in
        Akce.create ~slots:10 (fun f -> f ())
        >>= fun executor ->
        Akce.enqueue executor ~keys:[ "test1" ] (fun () ->
            Fut.Promise.set rendevous_test1 ()
            >>= fun () ->
            Fut.Promise.future trigger_test1 >>= fun () -> Fut.Promise.set finished_test1 ())
        >>= fun _ ->
        Fut.Promise.future rendevous_test1
        >>= fun () ->
        Fut.fork (Akce.drain_and_destroy executor >>= fun () -> Fut.Promise.set drained1 ())
        >>= fun _ ->
        Fut.fork
          (Akce.enqueue executor ~keys:[ "test1" ] (fun () -> assert false)
          >>= fun res ->
          assert (res = Error `Closed);
          Fut.return ())
        >>= fun _ -> Fut.Promise.set rendevous_test2 () >>= fun () -> Fut.return ()
      in
      ignore (Fut.run_with_state run dummy_state);
      assert (Fut.state (Fut.Promise.future finished_test1) = `Undet);
      assert (Fut.state (Fut.Promise.future rendevous_test1) = `Det ());
      assert (Fut.state (Fut.Promise.future rendevous_test2) = `Det ());
      assert (Fut.state (Fut.Promise.future drained1) = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set trigger_test1 ()) dummy_state);
      assert (Fut.state (Fut.Promise.future finished_test1) = `Det ());
      assert (Fut.state (Fut.Promise.future drained1) = `Det ());
      assert (Fut.state run = `Det ()))

let test_empty_key_list =
  Oth.test ~name:"Empty key list" (fun _ ->
      let rendevous_test1 = Fut.Promise.create () in
      let trigger_test1 = Fut.Promise.create () in
      let finished_test1 = Fut.Promise.create () in
      let rendevous_test2 = Fut.Promise.create () in
      let trigger_test2 = Fut.Promise.create () in
      let finished_test2 = Fut.Promise.create () in
      let run =
        let open Fut.Infix_monad in
        Akce.create ~slots:10 (fun f -> f ())
        >>= fun executor ->
        Akce.enqueue executor ~keys:[] (fun () ->
            Fut.Promise.set rendevous_test1 ()
            >>= fun () ->
            Fut.Promise.future trigger_test1 >>= fun () -> Fut.Promise.set finished_test1 ())
        >>= fun _ ->
        Akce.enqueue executor ~keys:[] (fun () ->
            Fut.Promise.set rendevous_test2 ()
            >>= fun () ->
            Fut.Promise.future trigger_test2 >>= fun () -> Fut.Promise.set finished_test2 ())
        >>= fun _ -> Akce.destroy executor
      in
      ignore (Fut.run_with_state run dummy_state);
      assert (Fut.state (Fut.Promise.future finished_test1) = `Undet);
      assert (Fut.state (Fut.Promise.future finished_test2) = `Undet);
      assert (Fut.state (Fut.Promise.future rendevous_test1) = `Det ());
      assert (Fut.state (Fut.Promise.future rendevous_test2) = `Det ());
      ignore (Fut.run_with_state (Fut.Promise.set trigger_test1 ()) dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set trigger_test2 ()) dummy_state);
      assert (Fut.state (Fut.Promise.future finished_test1) = `Det ());
      assert (Fut.state (Fut.Promise.future finished_test2) = `Det ());
      assert (Fut.state run = `Det ()))

let test_empty_key_list_one_lost =
  Oth.test ~name:"Empty key list one slot" (fun _ ->
      let rendevous_test1 = Fut.Promise.create () in
      let trigger_test1 = Fut.Promise.create () in
      let finished_test1 = Fut.Promise.create () in
      let rendevous_test2 = Fut.Promise.create () in
      let trigger_test2 = Fut.Promise.create () in
      let finished_test2 = Fut.Promise.create () in
      let run =
        let open Fut.Infix_monad in
        Akce.create ~slots:1 (fun f -> f ())
        >>= fun executor ->
        Akce.enqueue executor ~keys:[] (fun () ->
            Fut.Promise.set rendevous_test1 ()
            >>= fun () ->
            Fut.Promise.future trigger_test1 >>= fun () -> Fut.Promise.set finished_test1 ())
        >>= fun _ ->
        Akce.enqueue executor ~keys:[] (fun () ->
            Fut.Promise.set rendevous_test2 ()
            >>= fun () ->
            Fut.Promise.future trigger_test2 >>= fun () -> Fut.Promise.set finished_test2 ())
        >>= fun _ -> Akce.drain_and_destroy executor
      in
      ignore (Fut.run_with_state run dummy_state);
      assert (Fut.state (Fut.Promise.future finished_test1) = `Undet);
      assert (Fut.state (Fut.Promise.future finished_test2) = `Undet);
      assert (Fut.state (Fut.Promise.future rendevous_test1) = `Det ());
      assert (Fut.state (Fut.Promise.future rendevous_test2) = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set trigger_test1 ()) dummy_state);
      assert (Fut.state (Fut.Promise.future finished_test1) = `Det ());
      assert (Fut.state (Fut.Promise.future rendevous_test2) = `Det ());
      ignore (Fut.run_with_state (Fut.Promise.set trigger_test2 ()) dummy_state);
      assert (Fut.state (Fut.Promise.future finished_test2) = `Det ());
      assert (Fut.state run = `Det ()))

let () =
  Random.self_init ();
  Oth.(
    run
      (parallel
         [
           test_simple;
           test_non_overlapping_keys;
           test_overlapping_keys;
           test_multiple_drains_notified;
           test_slot_count_respected;
           test_would_lock_respected;
           test_draining_does_not_enqueue_work;
           test_empty_key_list;
           test_empty_key_list_one_lost;
         ]))
