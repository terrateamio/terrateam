(* Self-hosted checks for [Oth.run_groups], which drives this executable's exit code: two groups
   overlap in time, the [?after] group runs once both of them have finished and been torn down, and
   the run-level teardown comes last. This is the ordering a suite relies on when it overlaps the
   groups whose servers are independent, but keeps one group to itself.

   Checks go through [check] rather than [assert]: the release profile compiles with
   -noassert (code/dune), which elides [assert cond] outright, so an [assert]-based
   check here passes in CI no matter what the framework does. [failwith] is not
   elided. Deliberately not [Oth.Assert] either -- this file tests the framework,
   so its own checks should not route through it.

   The backend is [Oth_abb], not the synchronous [Oth]: the latter runs [parallel] sequentially, so
   it cannot show that two groups overlap. One run per executable, as in phases_test.ml: the runner
   reports its results and exits the process, so its exit code is the check. Both evaluators
   compute that code in the same place, so a green run here is the parity with [run_phases]. *)

module Oth_abb = Oth_abb.Make (Abb)

let check msg b = if not b then failwith ("check failed: " ^ msg)
let events = ref []
let record e = events := e :: !events
let got () = CCList.rev !events
let count e = CCList.count (CCString.equal e) (got ())

(* Position of a recorded event, so that a check on relative order is a comparison of two of
   these. *)
let index e =
  match CCList.find_index (CCString.equal e) (got ()) with
  | Some i -> i
  | None -> failwith ("check failed: " ^ e ^ " never happened")

let happens_before a b = check (Printf.sprintf "%s must happen before %s" a b) (index a < index b)

(* A group whose single test holds its slot for a while, so that the other group's body starts and
   ends inside it if the two groups really run at the same time. *)
let group name =
  Oth_abb.Group.make
    ~name
    ~setup:(fun () ->
      record (name ^ "_setup");
      Abb.Future.return (Ok ()))
    ~teardown:(fun () ->
      record (name ^ "_teardown");
      Abb.Future.return ())
    (fun () ->
      Oth_abb.test ~name:(name ^ " test") (fun () ->
          record (name ^ "_body_start");
          let open Abb.Future.Infix_monad in
          Abb.Sys.sleep 0.2 >>| fun () -> record (name ^ "_body_end")))

(* Its teardown is where the whole event list is complete, so the ordering checks live there. *)
let after_group =
  Oth_abb.Group.make
    ~name:"after"
    ~setup:(fun () ->
      record "after_setup";
      Abb.Future.return (Ok ()))
    ~teardown:(fun () ->
      record "after_teardown";
      check
        "each group ran its body exactly once"
        (count "a_body_start" = 1 && count "b_body_start" = 1);
      (* The groups overlap: [b] starts while [a] is still running. Under [run_phases] the first
         group's teardown would come before the second group's setup. *)
      happens_before "b_setup" "a_teardown";
      happens_before "b_body_start" "a_body_end";
      (* The tail waits for both groups' tests and for both their teardowns. *)
      happens_before "a_body_end" "after_setup";
      happens_before "b_body_end" "after_setup";
      happens_before "a_teardown" "after_setup";
      happens_before "b_teardown" "after_setup";
      Abb.Future.return ())
    (fun () ->
      Oth_abb.test ~name:"after test" (fun () ->
          record "after_test";
          Abb.Future.return ()))

let () =
  (* The backend reports a failing test by logging it, and logs go nowhere until a reporter is
     installed: without this a red check exits 1 saying nothing. *)
  Logs.set_reporter (Logs_fmt.reporter ());
  (* Two slots are all the two bodies need; the default of one would run them one at a time. *)
  Oth_abb.set_default_slots 2;
  Oth_abb.run_groups
    ~file:__FILE__
    ~setup:(fun () -> Abb.Future.return (Ok ()))
    ~teardown:(fun () ->
      check
        "the run-level teardown runs after the tail's teardown"
        (CCList.last_opt (got ()) = Some "after_teardown");
      record "global_teardown";
      Abb.Future.return ())
    ~after:[ after_group ]
    [ group "a"; group "b" ]
