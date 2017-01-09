module List = ListLabels

(*
 * This isn't here actually but will be used to propogate
 * options at some point
 *)
module State = struct
  type t = { log : string -> unit }

  let create () =
    { log = print_string }
end

module Test = struct
  type t = (State.t -> unit)
end

(*
 * Global state, boo, but refactorable later.
 *
 * Used to track if the run of tests was successful
 *)
let test_success = ref true

let dev_null = CCFun.const ()

let run_tests state test =
  test state

let serial tests state =
  List.iter ~f:(run_tests state) tests

let parallel = serial

let time_call f =
  let start = Sys.time () in
  let res = f () in
  let stop = Sys.time () in
  let sec = stop -. start in
  (sec, res)

let test ?(desc = "") ~name f state =
  let t = fun () -> CCResult.guard (fun () -> f state) in
  match time_call t with
    | (time, Ok ()) -> begin
      state.State.log (Printf.sprintf "Test: %s\t\tPASSED (%0.2f sec)\n" name time);
      ()
    end
    | (time, Error exn) -> begin
      state.State.log
        (Printf.sprintf "Test: %s\t\tFAILED (%0.2f sec)\nDescription:\n%s\nExn:\n%s\n%s\n"
           name
           time
           desc
           (Printexc.to_string exn)
           (Printexc.get_backtrace ()));
      test_success := false;
      ()
    end

let name ~name tst state =
  let t = fun () -> run_tests state tst in
  let (time, ()) = time_call t in
  state.State.log
    (Printf.sprintf "Test: %s\t\tELAPSED (%0.2f sec)\n" name time);
  ()

let result_test rtest state =
  let res = rtest state in
  match res with
    | Ok _ -> ()
    | Error _ -> assert false

let test_with_revops ?desc ~name ~revops tst =
  test
    ?desc
    ~name
    (fun state -> Revops.run_in_context revops (CCFun.flip tst state))

let exit_of_success () =
  match !test_success with
    | true -> 0
    | false -> 1

let run_all_tests state t =
  run_tests state t;
  exit (exit_of_success ())

let run t =
  run_all_tests (State.create ()) t

let loop n t =
  let rec loop state = function
    | i when i >= n ->
      ()
    | i ->
      let () = run_tests state t in
      loop state (i + 1)
  in
  (fun state -> loop state 0)

let timeout span t = failwith "timeout not implemented"

let verbose t state =
  let state = { State.log = print_string } in
  t state

let silent t state =
  let state = { State.log = dev_null } in
  t state
