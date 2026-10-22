(* Self-hosted check for [Oth.run_groups]: the groups' tests take the executor's slots in list
   order, whichever setup finishes first. A suite relies on this to start a long serial chain
   before the bulk of the run, by placing its group first.

   The first group's setup is the slow one, and the run has one slot, so the order in which the
   tests run is the order in which they entered the executor. Without the barrier between the
   setups and the tests, the second group's tests would enter first and run first.

   Checks go through [check] rather than [assert], for the reason groups_test.ml gives. *)

module Oth_abb = Oth_abb.Make (Abb)

let check msg b = if not b then failwith ("check failed: " ^ msg)
let events = ref []
let record e = events := e :: !events
let got () = CCList.rev !events

let group ~setup_delay name =
  Oth_abb.Group.make
    ~name
    ~setup:(fun () ->
      let open Abb.Future.Infix_monad in
      Abb.Sys.sleep setup_delay
      >>= fun () ->
      record (name ^ "_setup");
      Abb.Future.return (Ok ()))
    ~teardown:(fun () -> Abb.Future.return ())
    (fun () ->
      Oth_abb.parallel
        (CCList.map
           (fun i ->
             let test = Printf.sprintf "%s_%d" name i in
             Oth_abb.test ~name:test (fun () ->
                 record test;
                 Abb.Future.return ()))
           [ 1; 2 ]))

let () =
  Logs.set_reporter (Logs_fmt.reporter ());
  Oth_abb.set_default_slots 1;
  Oth_abb.run_groups
    ~file:__FILE__
    ~setup:(fun () -> Abb.Future.return (Ok ()))
    ~teardown:(fun () ->
      check
        "the tests run in list order, after both setups"
        (got () = [ "b_setup"; "a_setup"; "a_1"; "a_2"; "b_1"; "b_2" ]);
      Abb.Future.return ())
    [ group ~setup_delay:0.2 "a"; group ~setup_delay:0.0 "b" ]
