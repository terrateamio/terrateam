let basic_test =
  Oth.test ~desc:"Simple test that executes a sleep" ~name:"Basic sleep test" (fun _ ->
      let pool = Abb_thread_pool.create ~capacity:1 ~wait:Unix.pipe in
      let (wait, _) =
        Abb_thread_pool.enqueue
          pool
          ~f:(fun () -> Unix.sleep 1)
          ~trigger:(fun (_, trigger) _ -> Unix.close trigger)
      in
      let ret = Unix.read wait (Bytes.create 10) 0 10 in
      Abb_thread_pool.destroy pool;
      assert (ret = 0))

let parallel_test =
  Oth.test ~desc:"Verify work runs in parallel" ~name:"Parallel test" (fun _ ->
      let pool = Abb_thread_pool.create ~capacity:2 ~wait:Unix.pipe in
      let start = Unix.time () in
      let (wait1, _) =
        Abb_thread_pool.enqueue
          pool
          ~f:(fun () -> Unix.sleep 3)
          ~trigger:(fun (_, trigger) _ -> Unix.close trigger)
      in
      let (wait2, _) =
        Abb_thread_pool.enqueue
          pool
          ~f:(fun () -> Unix.sleep 3)
          ~trigger:(fun (_, trigger) _ -> Unix.close trigger)
      in
      let ret1 = Unix.read wait1 (Bytes.create 10) 0 10 in
      let ret2 = Unix.read wait2 (Bytes.create 10) 0 10 in
      let stop = Unix.time () in
      Abb_thread_pool.destroy pool;
      assert (ret1 = 0);
      assert (ret2 = 0);
      assert (stop -. start < 6.0))

let serialize_test =
  Oth.test ~desc:"Verify overcapacity work is serialized" ~name:"Serialize test" (fun _ ->
      let pool = Abb_thread_pool.create ~capacity:2 ~wait:Unix.pipe in
      let start = Unix.time () in
      let (wait1, _) =
        Abb_thread_pool.enqueue
          pool
          ~f:(fun () -> Unix.sleep 3)
          ~trigger:(fun (_, trigger) _ -> Unix.close trigger)
      in
      let (wait2, _) =
        Abb_thread_pool.enqueue
          pool
          ~f:(fun () -> Unix.sleep 3)
          ~trigger:(fun (_, trigger) _ -> Unix.close trigger)
      in
      let (wait3, _) =
        Abb_thread_pool.enqueue
          pool
          ~f:(fun () -> Unix.sleep 3)
          ~trigger:(fun (_, trigger) _ -> Unix.close trigger)
      in
      let ret1 = Unix.read wait1 (Bytes.create 10) 0 10 in
      let ret2 = Unix.read wait2 (Bytes.create 10) 0 10 in
      let ret3 = Unix.read wait3 (Bytes.create 10) 0 10 in
      let stop = Unix.time () in
      Abb_thread_pool.destroy pool;
      assert (ret1 = 0);
      assert (ret2 = 0);
      assert (ret3 = 0);
      assert (stop -. start > 3.0);
      assert (stop -. start < 9.0))

let () =
  Random.self_init ();
  Oth.(run (parallel [ basic_test; parallel_test; serialize_test ]))
