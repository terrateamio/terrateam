(* Self-hosted checks for [Oth.collect_tags], [Oth.Tag.should_run_env], and
   [Oth.run_phases] (which drives this executable's exit code).

   Checks go through [check] rather than [assert]: the release profile compiles with
   -noassert (code/dune), which elides [assert cond] outright, so an [assert]-based
   check here passes in CI no matter what the framework does. [failwith] is not
   elided. Deliberately not [Oth.Assert] either -- this file tests the framework,
   so its own checks should not route through it. *)

let check msg b = if not b then failwith ("check failed: " ^ msg)
let events = ref []
let record e = events := e :: !events
let got () = CCList.rev !events

(* A tree whose bodies must never execute under [collect_tags]. *)
let collect_tree =
  Oth.(
    parallel
      [
        test ~tags:[ "grp_a" ] ~name:"t1" (fun () -> failwith "body must not run");
        test ~name:"t2" (fun () -> failwith "body must not run");
      ])

let test_collect_tags () =
  let tag_sets = Oth.collect_tags ~file:"code/src/foo/foo_bar.ml" collect_tree in
  (* [all_tags] shape: default :: name :: declared tags @ file-derived tags. *)
  check
    "collect_tags shape"
    (tag_sets
    = [
        [ "default"; "t1"; "grp_a"; "foo"; "foo_bar.ml" ]; [ "default"; "t2"; "foo"; "foo_bar.ml" ];
      ])

let test_should_run_env () =
  let t1_tags = [ "default"; "t1"; "grp_a"; "foo"; "foo_bar.ml" ] in
  let t2_tags = [ "default"; "t2"; "foo"; "foo_bar.ml" ] in
  (* Unset (empty counts as unset): everything runs. *)
  Unix.putenv "OTH_TAGS" "";
  Unix.putenv "OTH_EXCLUDE_TAGS" "";
  check "unset runs t1" (Oth.Tag.should_run_env ~tags:t1_tags);
  check "unset runs t2" (Oth.Tag.should_run_env ~tags:t2_tags);
  (* Include filter selects only matching tag sets. *)
  Unix.putenv "OTH_TAGS" "grp_a";
  check "include selects t1" (Oth.Tag.should_run_env ~tags:t1_tags);
  check "include rejects t2" (not (Oth.Tag.should_run_env ~tags:t2_tags));
  (* Exclude beats include. *)
  Unix.putenv "OTH_EXCLUDE_TAGS" "t1";
  check "exclude beats include" (not (Oth.Tag.should_run_env ~tags:t1_tags));
  Unix.putenv "OTH_TAGS" "";
  Unix.putenv "OTH_EXCLUDE_TAGS" ""

(* Execution-semantics checks for [loop] and [serial], ported from the old
   code/tests/oth self-tests. They have to run as part of a real suite -- [collect_tags]
   deliberately does not execute bodies, and [run_phases] exits the process -- so they
   live inside the phase tree below and are verified in that phase's teardown. *)
let loop_iterations = 100
let loop_runs = ref 0
let serial_in_test = ref false

let combinator_tests () =
  Oth.serial
    [
      Oth.loop loop_iterations (Oth.test ~name:"loop body" (fun () -> incr loop_runs));
      Oth.serial
        (CCList.init 5 (fun i ->
             Oth.test ~name:(Printf.sprintf "serial %d" i) (fun () ->
                 (* If serial interleaved, another body would observe this set. *)
                 check "serial must not interleave" (not !serial_in_test);
                 serial_in_test := true;
                 serial_in_test := false)));
    ]

(* [run_phases] ordering: the global setup wraps everything, each phase's
   teardown completes before the next phase's setup starts, and phase setups
   see the run-level setup value. Drives this executable's exit. *)
let run_phases_ordering () =
  Oth.(
    run_phases
      ~file:__FILE__
      ~setup:(fun () ->
        record "global_setup";
        Ok "g")
      ~teardown:(fun g ->
        check "global teardown sees setup value" (g = "g");
        record "global_teardown";
        check
          "phase ordering"
          (got ()
          = [
              "global_setup";
              "p1_setup";
              "p1_test";
              "p1_teardown";
              "p2_setup";
              "p2_test";
              "p2_teardown";
              "p3_setup";
              "p3_teardown";
              "global_teardown";
            ]))
      [
        Phase.make
          ~name:"p1"
          ~setup:(fun g ->
            check "p1 setup sees global value" (g = "g");
            record "p1_setup";
            Ok 1)
          ~teardown:(fun v ->
            check "p1 teardown sees phase value" (v = 1);
            record "p1_teardown")
          (fun v ->
            test ~name:"p1 test" (fun () ->
                check "p1 test sees phase value" (v = 1);
                record "p1_test"));
        Phase.make
          ~name:"p2"
          ~setup:(fun g ->
            check "p2 setup sees global value" (g = "g");
            (* The previous phase must be fully torn down before this setup runs. *)
            check
              "p1 fully torn down before p2 setup"
              (got () = [ "global_setup"; "p1_setup"; "p1_test"; "p1_teardown" ]);
            record "p2_setup";
            Ok 2)
          ~teardown:(fun v ->
            check "p2 teardown sees phase value" (v = 2);
            record "p2_teardown")
          (fun v ->
            test ~name:"p2 test" (fun () ->
                check "p2 test sees phase value" (v = 2);
                record "p2_test"));
        Phase.make
          ~name:"combinators"
          ~setup:(fun _ ->
            record "p3_setup";
            Ok ())
          ~teardown:(fun () ->
            check
              (Printf.sprintf "loop ran the body %d times, expected %d" !loop_runs loop_iterations)
              (!loop_runs = loop_iterations);
            record "p3_teardown")
          (fun () -> combinator_tests ());
      ])

let () =
  test_collect_tags ();
  test_should_run_env ();
  run_phases_ordering ()
