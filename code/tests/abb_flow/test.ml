module Abb = Abb_scheduler_select
module Oth_abb = Oth_abb.Make (Abb)

module Id : Abb_flow.ID with type t = string = struct
  type t = string [@@deriving show, eq]

  let to_string = CCFun.id
  let of_string = CCOption.return
end

module State = struct
  type of_string_err = unit [@@deriving show]
  type step_err = unit [@@deriving show]
  type t = int

  let to_string = CCInt.to_string

  let of_string s =
    match CCInt.of_string s with
    | Some n -> Ok n
    | None -> Error ()

  let merge n1 n2 = n1 + n2
end

module Flow = Abb_flow.Make (Abb.Future) (Id) (State)

let test_success =
  Oth_abb.test ~name:"Success" (fun _ ->
      let flow =
        Flow.Flow.action
          [ Flow.Step.make ~id:"one" ~f:(fun () n -> Abb.Future.return (`Success (n + 1))) () ]
      in
      let flow = Flow.create flow in
      let open Abb.Future.Infix_monad in
      Flow.run () 0 flow
      >>= function
      | `Success n ->
          assert (n = 1);
          Abb.Future.return ()
      | `Failure _ -> assert false
      | `Yield _ -> assert false)

let test_failure =
  Oth_abb.test ~name:"Failure" (fun _ ->
      let flow =
        Flow.Flow.action
          [ Flow.Step.make ~id:"one" ~f:(fun () n -> Abb.Future.return (`Failure ())) () ]
      in
      let flow = Flow.create flow in
      let open Abb.Future.Infix_monad in
      Flow.run () 0 flow
      >>= function
      | `Success _ -> assert false
      | `Failure _ -> Abb.Future.return ()
      | `Yield _ -> assert false)

let test_yield =
  Oth_abb.test ~name:"Yield" (fun _ ->
      let flow =
        Flow.Flow.action
          [
            Flow.Step.make
              ~id:"one"
              ~f:(fun () -> function
                | 0 -> Abb.Future.return (`Yield 0)
                | n -> Abb.Future.return (`Success (n + 1)))
              ();
          ]
      in
      let flow = Flow.create flow in
      let open Abb.Future.Infix_monad in
      Flow.run () 0 flow
      >>= function
      | `Success _ -> assert false
      | `Failure _ -> Abb.Future.return ()
      | `Yield yield -> (
          let resume = Flow.Yield.set_state (Flow.Yield.state yield + 1) yield in
          Flow.resume () resume flow
          >>= function
          | `Success n ->
              assert (n = 2);
              Abb.Future.return ()
          | `Failure _ -> assert false
          | `Yield _ -> assert false))

let test_exit_early =
  Oth_abb.test ~name:"Exit early" (fun _ ->
      let flow =
        Flow.Flow.seq
          (Flow.Flow.action
             [ Flow.Step.make ~id:"one" ~f:(fun () n -> Abb.Future.return (`Success (n + 1))) () ])
          (Flow.Flow.choice
             ~id:"choice"
             ~f:(fun _ n ->
               if n = 1 then Abb.Future.return (Ok ("exit", n))
               else Abb.Future.return (Ok ("two", n)))
             [
               ( "two",
                 Flow.Flow.action
                   [
                     Flow.Step.make
                       ~id:"two"
                       ~f:(fun () n -> Abb.Future.return (`Success (n + 1)))
                       ();
                   ] );
               ( "exit",
                 Flow.Flow.action
                   [ Flow.Step.make ~id:"exit" ~f:(fun () n -> Abb.Future.return (`Success n)) () ]
               );
             ])
      in
      let flow = Flow.create flow in
      let open Abb.Future.Infix_monad in
      Flow.run () 0 flow
      >>= function
      | `Success n ->
          assert (n = 1);
          Abb.Future.return ()
      | `Failure _ -> assert false
      | `Yield _ -> assert false)

let test_multistep_flow =
  Oth_abb.test ~name:"Multi-step flow" (fun _ ->
      let flow =
        Flow.Flow.seq
          (Flow.Flow.action
             [ Flow.Step.make ~id:"one" ~f:(fun () n -> Abb.Future.return (`Success (n + 1))) () ])
          (Flow.Flow.action
             [ Flow.Step.make ~id:"two" ~f:(fun () n -> Abb.Future.return (`Success (n + 1))) () ])
      in
      let flow = Flow.create flow in
      let open Abb.Future.Infix_monad in
      Flow.run () 0 flow
      >>= function
      | `Success n ->
          assert (n = 2);
          Abb.Future.return ()
      | `Failure _ -> assert false
      | `Yield _ -> assert false)

let test_multistep_with_logging =
  Oth_abb.test ~name:"Multi-step flow with logging" (fun _ ->
      let flow =
        Flow.Flow.action
          [
            Flow.Step.make ~id:"one" ~f:(fun () n -> Abb.Future.return (`Success (n + 1))) ();
            Flow.Step.make ~id:"two" ~f:(fun () n -> Abb.Future.return (`Success (n + 1))) ();
            Flow.Step.make ~id:"three" ~f:(fun () n -> Abb.Future.return (`Success (n + 1))) ();
          ]
      in
      let executed_steps = ref [] in
      let log = function
        | Flow.Event.Step_start (step, _) -> executed_steps := Flow.Step.id step :: !executed_steps
        | Flow.Event.Step_end _ -> ()
        | Flow.Event.Choice_start _
        | Flow.Event.Choice_end _
        | Flow.Event.Finally_start _
        | Flow.Event.Finally_resume _
        | Flow.Event.Recover_choice _
        | Flow.Event.Recover_start _ -> ()
      in
      let flow = Flow.create ~log flow in
      let open Abb.Future.Infix_monad in
      Flow.run () 0 flow
      >>= function
      | `Success n ->
          assert (n = 3);
          assert (!executed_steps = [ "one"; "two"; "three" ]);
          Abb.Future.return ()
      | `Failure _ -> assert false
      | `Yield _ -> assert false)

let test_yield_with_choice =
  Oth_abb.test ~name:"Yield with choice" (fun _ ->
      let flow =
        Flow.Flow.seq
          (Flow.Flow.action
             [ Flow.Step.make ~id:"one" ~f:(fun () n -> Abb.Future.return (`Success (n + 1))) () ])
          (Flow.Flow.choice
             ~id:"left_or_right"
             ~f:(fun () n ->
               if n > 0 then Abb.Future.return (Ok ("left", n))
               else Abb.Future.return (Ok ("right", n)))
             [
               ( "right",
                 Flow.Flow.action
                   [ Flow.Step.make ~id:"right" ~f:(fun () _ -> failwith "WRONG") () ] );
               ( "left",
                 Flow.Flow.action
                   [
                     Flow.Step.make
                       ~id:"exec_left"
                       ~f:(fun () -> function
                         | 1 -> Abb.Future.return (`Yield 1)
                         | n -> Abb.Future.return (`Success n))
                       ();
                   ] );
             ])
      in
      let flow = Flow.create flow in
      let open Abb.Future.Infix_monad in
      Flow.run () 0 flow
      >>= function
      | `Success _ -> assert false
      | `Failure _ -> Abb.Future.return ()
      | `Yield yield -> (
          let resume = Flow.Yield.set_state (Flow.Yield.state yield + 1) yield in
          Flow.resume () resume flow
          >>= function
          | `Success n ->
              assert (n = 2);
              Abb.Future.return ()
          | `Failure _ -> assert false
          | `Yield _ -> assert false))

let test_yield_with_choice_and_multiple_resumes =
  Oth_abb.test ~name:"Yield with choice and multiple resumes" (fun _ ->
      let flow =
        Flow.Flow.seq
          (Flow.Flow.action
             [ Flow.Step.make ~id:"one" ~f:(fun () n -> Abb.Future.return (`Success (n + 1))) () ])
          (Flow.Flow.choice
             ~id:"left_or_right"
             ~f:(fun () n ->
               if n > 0 then Abb.Future.return (Ok ("left", n))
               else Abb.Future.return (Ok ("right", n)))
             [
               ( "right",
                 Flow.Flow.action
                   [ Flow.Step.make ~id:"right" ~f:(fun () _ -> failwith "WRONG") () ] );
               ( "left",
                 Flow.Flow.action
                   [
                     Flow.Step.make
                       ~id:"exec_left"
                       ~f:(fun () -> function
                         | n when n > 2 -> Abb.Future.return (`Success n)
                         | n -> Abb.Future.return (`Yield n))
                       ();
                   ] );
             ])
      in
      let flow = Flow.create flow in
      let open Abb.Future.Infix_monad in
      Flow.run () 0 flow
      >>= function
      | `Success _ -> assert false
      | `Failure _ -> Abb.Future.return ()
      | `Yield yield -> (
          let resume = Flow.Yield.set_state (Flow.Yield.state yield + 1) yield in
          Flow.resume () resume flow
          >>= function
          | `Success _ -> assert false
          | `Failure _ -> assert false
          | `Yield yield -> (
              let resume = Flow.Yield.set_state (Flow.Yield.state yield + 1) yield in
              Flow.resume () resume flow
              >>= function
              | `Success n ->
                  assert (n = 3);
                  Abb.Future.return ()
              | `Failure _ -> assert false
              | `Yield _ -> assert false)))

let test_yield_serialization =
  Oth_abb.test ~name:"Yield serialization" (fun _ ->
      let flow =
        Flow.Flow.seq
          (Flow.Flow.action
             [ Flow.Step.make ~id:"one" ~f:(fun () n -> Abb.Future.return (`Success (n + 1))) () ])
          (Flow.Flow.choice
             ~id:"choice"
             ~f:(fun () n ->
               if n > 0 then Abb.Future.return (Ok ("left", n))
               else Abb.Future.return (Ok ("right", n)))
             [
               ( "right",
                 Flow.Flow.action
                   [ Flow.Step.make ~id:"right" ~f:(fun () _ -> failwith "WRONG") () ] );
               ( "left",
                 Flow.Flow.action
                   [
                     Flow.Step.make
                       ~id:"exec_left"
                       ~f:(fun () -> function
                         | 1 -> Abb.Future.return (`Yield 1)
                         | n -> Abb.Future.return (`Success n))
                       ();
                   ] );
             ])
      in
      let flow = Flow.create flow in
      let open Abb.Future.Infix_monad in
      Flow.run () 0 flow
      >>= function
      | `Success _ -> assert false
      | `Failure _ -> Abb.Future.return ()
      | `Yield yield -> (
          let yield = Flow.Yield.to_string yield in
          let yield = CCResult.get_exn (Flow.Yield.of_string yield) in
          let resume = Flow.Yield.set_state (Flow.Yield.state yield + 1) yield in
          Flow.resume () resume flow
          >>= function
          | `Success n ->
              assert (n = 2);
              Abb.Future.return ()
          | `Failure _ -> assert false
          | `Yield _ -> assert false))

let test_exception =
  Oth_abb.test ~name:"Exception" (fun _ ->
      let flow = Flow.Flow.action [ Flow.Step.make ~id:"one" ~f:(fun () _ -> failwith "err") () ] in
      let flow = Flow.create flow in
      let open Abb.Future.Infix_monad in
      Flow.run () 0 flow
      >>= function
      | `Success _ -> assert false
      | `Failure (`Step_exn_err _) -> Abb.Future.return ()
      | `Failure (`Step_err _) -> assert false
      | `Yield _ -> assert false)

let test_finally_success =
  Oth_abb.test ~name:"Finally success" (fun _ ->
      let v = ref 0 in
      let flow =
        Flow.create
          Flow.Flow.(
            finally
              ~id:"finally"
              (action
                 [
                   Flow.Step.make
                     ~id:"one"
                     ~f:(fun () state ->
                       incr v;
                       Abb.Future.return (`Success state))
                     ();
                 ])
              ~finally:
                (action
                   [
                     Flow.Step.make
                       ~id:"two"
                       ~f:(fun () state ->
                         incr v;
                         Abb.Future.return (`Success state))
                       ();
                   ]))
      in
      let open Abb.Future.Infix_monad in
      Flow.run () 0 flow
      >>= function
      | `Success _ ->
          assert (!v = 2);
          Abb.Future.return ()
      | `Failure _ -> assert false
      | `Yield _ -> assert false)

let test_finally_failure =
  Oth_abb.test ~name:"Finally failure" (fun _ ->
      let v = ref 0 in
      let flow =
        Flow.create
          Flow.Flow.(
            finally
              ~id:"finally"
              (action
                 [
                   Flow.Step.make
                     ~id:"one"
                     ~f:(fun () state ->
                       incr v;
                       Abb.Future.return (`Failure ()))
                     ();
                 ])
              ~finally:
                (action
                   [
                     Flow.Step.make
                       ~id:"two"
                       ~f:(fun () state ->
                         incr v;
                         Abb.Future.return (`Success state))
                       ();
                   ]))
      in
      let open Abb.Future.Infix_monad in
      Flow.run () 0 flow
      >>= function
      | `Success _ -> assert false
      | `Failure _ ->
          assert (!v = 2);
          Abb.Future.return ()
      | `Yield _ -> assert false)

let test_finally_yield =
  Oth_abb.test ~name:"Finally yield" (fun _ ->
      let v = ref 0 in
      let flow =
        Flow.create
          Flow.Flow.(
            finally
              ~id:"finally"
              (action
                 [
                   Flow.Step.make
                     ~id:"one"
                     ~f:(fun () state ->
                       incr v;
                       Abb.Future.return (`Success state))
                     ();
                   Flow.Step.make
                     ~id:"two"
                     ~f:(fun () state ->
                       if state < 2 then (
                         incr v;
                         Abb.Future.return (`Yield (state + 1)))
                       else (
                         incr v;
                         Abb.Future.return (`Success state)))
                     ();
                 ])
              ~finally:
                (action
                   [
                     Flow.Step.make
                       ~id:"three"
                       ~f:(fun () state ->
                         incr v;
                         Abb.Future.return (`Success state))
                       ();
                   ]))
      in
      let open Abb.Future.Infix_monad in
      Flow.run () 0 flow
      >>= function
      | `Success _ -> assert false
      | `Failure _ -> assert false
      | `Yield resume -> (
          assert (!v = 2);
          Flow.resume () resume flow
          >>= function
          | `Success _ -> assert false
          | `Failure _ -> assert false
          | `Yield resume -> (
              assert (!v = 3);
              Flow.resume () resume flow
              >>= function
              | `Success _ ->
                  assert (!v = 5);
                  Abb.Future.return ()
              | `Failure _ -> assert false
              | `Yield _ -> assert false)))

let test_recover_success =
  Oth_abb.test ~name:"Recover success" (fun _ ->
      let v = ref 0 in
      let flow =
        Flow.create
          Flow.Flow.(
            recover
              ~id:"main"
              (action
                 [
                   Flow.Step.make
                     ~id:"one"
                     ~f:(fun () state ->
                       incr v;
                       Abb.Future.return (`Success state))
                     ();
                 ])
              ~f:(fun _ state _ -> Abb.Future.return (Ok ("all", state)))
              ~recover:
                [
                  ( "all",
                    action
                      [
                        Flow.Step.make
                          ~id:"two"
                          ~f:(fun () state ->
                            incr v;
                            Abb.Future.return (`Success state))
                          ();
                      ] );
                ])
      in
      let open Abb.Future.Infix_monad in
      Flow.run () 0 flow
      >>= function
      | `Success _ ->
          assert (!v = 1);
          Abb.Future.return ()
      | `Failure _ -> assert false
      | `Yield _ -> assert false)

let test_recover_failure =
  Oth_abb.test ~name:"Recover failure" (fun _ ->
      let v = ref 0 in
      let flow =
        Flow.create
          Flow.Flow.(
            recover
              ~id:"main"
              (action
                 [
                   Flow.Step.make
                     ~id:"one"
                     ~f:(fun () state ->
                       incr v;
                       Abb.Future.return (`Failure ()))
                     ();
                 ])
              ~f:(fun _ state _ -> Abb.Future.return (Ok ("all", state)))
              ~recover:
                [
                  ( "all",
                    action
                      [
                        Flow.Step.make
                          ~id:"two"
                          ~f:(fun () state ->
                            incr v;
                            Abb.Future.return (`Success state))
                          ();
                      ] );
                ])
      in
      let open Abb.Future.Infix_monad in
      Flow.run () 0 flow
      >>= function
      | `Success _ ->
          assert (!v = 2);
          Abb.Future.return ()
      | `Failure _ -> assert false
      | `Yield _ -> assert false)

let test_recover_yield_success =
  Oth_abb.test ~name:"Finally yield success" (fun _ ->
      let v = ref 0 in
      let flow =
        Flow.create
          Flow.Flow.(
            recover
              ~id:"main"
              (action
                 [
                   Flow.Step.make
                     ~id:"one"
                     ~f:(fun () state ->
                       incr v;
                       Abb.Future.return (`Success state))
                     ();
                   Flow.Step.make
                     ~id:"two"
                     ~f:(fun () state ->
                       if state < 2 then (
                         incr v;
                         Abb.Future.return (`Yield (state + 1)))
                       else (
                         incr v;
                         Abb.Future.return (`Success state)))
                     ();
                 ])
              ~f:(fun _ state _ -> Abb.Future.return (Ok ("all", state)))
              ~recover:
                [
                  ( "all",
                    action
                      [
                        Flow.Step.make
                          ~id:"three"
                          ~f:(fun () state ->
                            incr v;
                            Abb.Future.return (`Success state))
                          ();
                      ] );
                ])
      in
      let open Abb.Future.Infix_monad in
      Flow.run () 0 flow
      >>= function
      | `Success _ -> assert false
      | `Failure _ -> assert false
      | `Yield resume -> (
          assert (!v = 2);
          Flow.resume () resume flow
          >>= function
          | `Success _ -> assert false
          | `Failure _ -> assert false
          | `Yield resume -> (
              assert (!v = 3);
              Flow.resume () resume flow
              >>= function
              | `Success _ ->
                  assert (!v = 4);
                  Abb.Future.return ()
              | `Failure _ -> assert false
              | `Yield _ -> assert false)))

let test_recover_yield_failure =
  Oth_abb.test ~name:"Finally yield failure" (fun _ ->
      let v = ref 0 in
      let flow =
        Flow.create
          Flow.Flow.(
            recover
              ~id:"main"
              (action
                 [
                   Flow.Step.make
                     ~id:"one"
                     ~f:(fun () state ->
                       incr v;
                       Abb.Future.return (`Success state))
                     ();
                   Flow.Step.make
                     ~id:"two"
                     ~f:(fun () state ->
                       if state < 2 then (
                         incr v;
                         Abb.Future.return (`Yield (state + 1)))
                       else (
                         incr v;
                         Abb.Future.return (`Failure ())))
                     ();
                 ])
              ~f:(fun _ state _ -> Abb.Future.return (Ok ("all", state)))
              ~recover:
                [
                  ( "all",
                    action
                      [
                        Flow.Step.make
                          ~id:"three"
                          ~f:(fun () state ->
                            incr v;
                            Abb.Future.return (`Success state))
                          ();
                      ] );
                ])
      in
      let open Abb.Future.Infix_monad in
      Flow.run () 0 flow
      >>= function
      | `Success _ -> assert false
      | `Failure _ -> assert false
      | `Yield resume -> (
          assert (!v = 2);
          Flow.resume () resume flow
          >>= function
          | `Success _ -> assert false
          | `Failure _ -> assert false
          | `Yield resume -> (
              assert (!v = 3);
              Flow.resume () resume flow
              >>= function
              | `Success _ ->
                  assert (!v = 5);
                  Abb.Future.return ()
              | `Failure _ -> assert false
              | `Yield _ -> assert false)))

let test_recover_failure_yield_success =
  Oth_abb.test ~name:"Finally failure yield success" (fun _ ->
      let v = ref 0 in
      let flow =
        Flow.create
          Flow.Flow.(
            recover
              ~id:"main"
              (action
                 [
                   Flow.Step.make
                     ~id:"one"
                     ~f:(fun () state ->
                       incr v;
                       Abb.Future.return (`Success state))
                     ();
                   Flow.Step.make
                     ~id:"two"
                     ~f:(fun () state ->
                       incr v;
                       Abb.Future.return (`Failure ()))
                     ();
                 ])
              ~f:(fun _ state _ -> Abb.Future.return (Ok ("all", state)))
              ~recover:
                [
                  ( "all",
                    action
                      [
                        Flow.Step.make
                          ~id:"three"
                          ~f:(fun () state ->
                            if state < 2 then (
                              incr v;
                              Abb.Future.return (`Yield (state + 1)))
                            else (
                              incr v;
                              Abb.Future.return (`Success state)))
                          ();
                      ] );
                ])
      in
      let open Abb.Future.Infix_monad in
      Flow.run () 0 flow
      >>= function
      | `Success _ -> assert false
      | `Failure _ -> assert false
      | `Yield resume -> (
          assert (!v = 3);
          Flow.resume () resume flow
          >>= function
          | `Success _ -> assert false
          | `Failure _ -> assert false
          | `Yield resume -> (
              assert (!v = 4);
              Flow.resume () resume flow
              >>= function
              | `Success _ ->
                  assert (!v = 5);
                  Abb.Future.return ()
              | `Failure _ -> assert false
              | `Yield _ -> assert false)))

let test =
  Oth_abb.(
    to_sync_test
      (parallel
         [
           test_success;
           test_failure;
           test_yield;
           test_exit_early;
           test_multistep_flow;
           test_yield_with_choice;
           test_yield_with_choice_and_multiple_resumes;
           test_yield_serialization;
           test_exception;
           test_finally_success;
           test_finally_failure;
           test_finally_yield;
           test_recover_success;
           test_recover_failure;
           test_recover_yield_success;
           test_recover_yield_failure;
           test_recover_failure_yield_success;
         ]))

let () =
  Random.self_init ();
  Oth.run test
