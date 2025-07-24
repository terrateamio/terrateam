module Fut = Abb_fut.Make (struct
  type t = unit
end)

module Fut_comb = Abb_future_combinators.Make (Fut)

let dummy_state = Abb_fut.State.create ()

let first1 =
  Oth.test ~desc:"first returns determined future" ~name:"first with one determined" (fun _ ->
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let res = Fut_comb.first (Fut.Promise.future p1) (Fut.Promise.future p2) in
      ignore (Fut.run_with_state res dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set p1 1) dummy_state);
      match Fut.state res with
      | `Det (v, fut) ->
          assert (v = 1);
          assert (Fut.state fut = `Undet)
      | `Undet | `Aborted | `Exn _ -> assert false)

let first2 =
  Oth.test ~desc:"first returns determined future" ~name:"first with both determined" (fun _ ->
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let res = Fut_comb.first (Fut.Promise.future p1) (Fut.Promise.future p2) in
      ignore (Fut.run_with_state res dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set p1 1) dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set p2 2) dummy_state);
      match Fut.state res with
      | `Det (v, fut) -> (
          assert (v = 1);
          match Fut.state fut with
          | `Det v -> assert (v = 2)
          | `Undet | `Aborted | `Exn _ -> assert false)
      | `Undet | `Aborted | `Exn _ -> assert false)

let first3 =
  Oth.test ~desc:"Abort aborts the whole thing" ~name:"Abort first" (fun _ ->
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let res = Fut_comb.first (Fut.Promise.future p1) (Fut.Promise.future p2) in
      ignore (Fut.run_with_state res dummy_state);
      ignore (Fut.run_with_state (Fut.abort res) dummy_state);
      assert (Fut.state res = `Aborted);
      assert (Fut.state (Fut.Promise.future p1) = `Aborted);
      assert (Fut.state (Fut.Promise.future p2) = `Aborted))

let firstl1 =
  Oth.test ~desc:"firstl returns determined future" ~name:"firstl with one determined" (fun _ ->
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let res = Fut_comb.firstl [ Fut.Promise.future p1; Fut.Promise.future p2 ] in
      ignore (Fut.run_with_state res dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set p1 1) dummy_state);
      match Fut.state res with
      | `Det (v, [ fut ]) ->
          assert (v = 1);
          assert (Fut.state fut = `Undet)
      | `Det _ -> assert false
      | `Undet | `Aborted | `Exn _ -> assert false)

let firstl2 =
  Oth.test ~desc:"firstl returns determined future" ~name:"firstl with both determined" (fun _ ->
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let res = Fut_comb.firstl [ Fut.Promise.future p1; Fut.Promise.future p2 ] in
      ignore (Fut.run_with_state res dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set p1 1) dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set p2 2) dummy_state);
      match Fut.state res with
      | `Det (v, [ fut ]) -> (
          assert (v = 1);
          match Fut.state fut with
          | `Det v -> assert (v = 2)
          | `Undet | `Aborted | `Exn _ -> assert false)
      | `Det _ -> assert false
      | `Undet | `Aborted | `Exn _ -> assert false)

let firstl3 =
  Oth.test ~desc:"Abort aborts the whole thing" ~name:"Abort firstl" (fun _ ->
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let res = Fut_comb.firstl [ Fut.Promise.future p1; Fut.Promise.future p2 ] in
      ignore (Fut.run_with_state res dummy_state);
      ignore (Fut.run_with_state (Fut.abort res) dummy_state);
      assert (Fut.state res = `Aborted);
      assert (Fut.state (Fut.Promise.future p1) = `Aborted);
      assert (Fut.state (Fut.Promise.future p2) = `Aborted))

let map1 =
  Oth.test ~desc:"Simple map test" ~name:"Simple map" (fun _ ->
      let vs = [ 1; 2; 3 ] in
      let fut = Fut_comb.List.map ~f:Fut.return vs in
      ignore (Fut.run_with_state fut dummy_state);
      assert (Fut.state fut = `Det [ 1; 2; 3 ]))

let map2 =
  Oth.test ~desc:"Simple map test" ~name:"Simple map" (fun _ ->
      let vs = [ 1; 2; 3 ] in
      let fut = Fut_comb.List.map ~f:Fut.return vs in
      ignore (Fut.run_with_state fut dummy_state);
      assert (Fut.state fut = `Det [ 1; 2; 3 ]))

let firstl4 =
  Oth.test
    ~desc:"Aborting one of the inputs aborts the whole thing"
    ~name:"Abort firstl input"
    (fun _ ->
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let res = Fut_comb.firstl [ Fut.Promise.future p1; Fut.Promise.future p2 ] in
      ignore (Fut.run_with_state res dummy_state);
      ignore (Fut.run_with_state (Fut.abort (Fut.Promise.future p1)) dummy_state);
      assert (Fut.state res = `Aborted);
      assert (Fut.state (Fut.Promise.future p1) = `Aborted);
      assert (Fut.state (Fut.Promise.future p2) = `Aborted))

let first4 =
  Oth.test
    ~desc:"Aborting one of the inputs aborts the whole thing"
    ~name:"Abort first input"
    (fun _ ->
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let res = Fut_comb.first (Fut.Promise.future p1) (Fut.Promise.future p2) in
      ignore (Fut.run_with_state res dummy_state);
      ignore (Fut.run_with_state (Fut.abort (Fut.Promise.future p1)) dummy_state);
      assert (Fut.state res = `Aborted);
      assert (Fut.state (Fut.Promise.future p1) = `Aborted);
      assert (Fut.state (Fut.Promise.future p2) = `Aborted))

let with_finally_success =
  Oth.test ~desc:"Test the finally block is run on success" ~name:"with_finally success" (fun _ ->
      let finally_exec = ref 0 in
      let p = Fut.Promise.create () in
      let fut =
        Fut_comb.with_finally
          (fun () -> Fut.Promise.future p)
          ~finally:(fun () ->
            incr finally_exec;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set p ()) dummy_state);
      assert (!finally_exec > 0);
      assert (!finally_exec = 1);
      assert (Fut.state fut = `Det ()))

let with_finally_aborted =
  Oth.test ~desc:"Test the finally block is run on abort" ~name:"with_finally aborted" (fun _ ->
      let finally_exec = ref 0 in
      let p = Fut.Promise.create () in
      let fut =
        Fut_comb.with_finally
          (fun () -> Fut.Promise.future p)
          ~finally:(fun () ->
            incr finally_exec;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.abort (Fut.Promise.future p)) dummy_state);
      assert (!finally_exec > 0);
      assert (!finally_exec = 1);
      assert (Fut.state fut = `Aborted))

let with_finally_aborted_complete =
  Oth.test
    ~desc:"Test the finally block finishes before next step"
    ~name:"with_finally aborted complete"
    (fun _ ->
      let finally_exec = ref 0 in
      let next_step_finally_count = ref 0 in
      let trigger_finally_step = Fut.Promise.create () in
      let p = Fut.Promise.create () in
      let fut =
        let open Fut.Infix_monad in
        Fut.await
          (Fut_comb.with_finally
             (fun () -> Fut.Promise.future p)
             ~finally:(fun () ->
               Fut.Promise.future trigger_finally_step
               >>= fun () ->
               incr finally_exec;
               Fut.return ()))
        >>| fun _ -> next_step_finally_count := !finally_exec
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.abort (Fut.Promise.future p)) dummy_state);
      assert (!finally_exec = 0);
      assert (!next_step_finally_count = 0);
      ignore (Fut.run_with_state (Fut.Promise.set trigger_finally_step ()) dummy_state);
      assert (!finally_exec = 1);
      assert (!next_step_finally_count = 1);
      assert (Fut.state fut = `Det ()))

let with_finally_exn =
  Oth.test
    ~desc:"Test the finally block is run on a fut determining to an exn"
    ~name:"with_finally exn"
    (fun _ ->
      let finally_exec = ref 0 in
      let p = Fut.Promise.create () in
      let fut =
        Fut_comb.with_finally
          (fun () -> Fut.Promise.future p)
          ~finally:(fun () ->
            incr finally_exec;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set_exn p (Failure "foo", None)) dummy_state);
      assert (!finally_exec > 0);
      assert (!finally_exec = 1);
      match Fut.state fut with
      | `Exn (Failure _, None) -> ()
      | _ -> assert false)

let with_finally_raise =
  Oth.test
    ~desc:"Test the finally block is run on raising in the function"
    ~name:"with_finally raise"
    (fun _ ->
      let finally_exec = ref 0 in
      let fut =
        Fut_comb.with_finally
          (fun () -> failwith "foo")
          ~finally:(fun () ->
            incr finally_exec;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      assert (!finally_exec > 0);
      assert (!finally_exec = 1);
      match Fut.state fut with
      | `Exn (Failure _, Some _) -> ()
      | _ -> assert false)

let with_finally_exn_in_finally =
  Oth.test
    ~desc:"Test the finally block where the finally throws an exception"
    ~name:"with_finally exn in finally"
    (fun _ ->
      let fut =
        Fut_comb.with_finally (fun () -> Fut.return ()) ~finally:(fun () -> failwith "finally")
      in
      ignore (Fut.run_with_state fut dummy_state);
      match Fut.state fut with
      | `Exn (Failure msg, Some _) ->
          assert (msg = "finally");
          ()
      | `Aborted -> assert false
      | `Undet -> assert false
      | `Exn _ -> assert false
      | `Det _ -> assert false)

let with_finally_exn_in_body_and_finally =
  Oth.test
    ~desc:"Test the finally block where the body and finally throws an exception"
    ~name:"with_finally exn in body and finally"
    (fun _ ->
      let fut =
        Fut_comb.with_finally (fun () -> failwith "body") ~finally:(fun () -> failwith "finally")
      in
      ignore (Fut.run_with_state fut dummy_state);
      match Fut.state fut with
      | `Exn (Failure msg, Some _) ->
          assert (msg = "finally");
          ()
      | `Aborted -> assert false
      | `Undet -> assert false
      | `Exn _ -> assert false
      | `Det _ -> assert false)

let with_finally_aborted_from_outside =
  Oth.test
    ~desc:"Test the finally block is run on abort from the outside"
    ~name:"with_finally aborted outside"
    (fun _ ->
      let finally_exec = ref 0 in
      let p = Fut.Promise.create () in
      let fut =
        Fut_comb.with_finally
          (fun () -> Fut.Promise.future p)
          ~finally:(fun () ->
            incr finally_exec;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.abort fut) dummy_state);
      assert (!finally_exec > 0);
      assert (!finally_exec = 1);
      assert (Fut.state fut = `Aborted);
      assert (Fut.state (Fut.Promise.future p) = `Aborted))

let with_finally_nested_raise =
  Oth.test ~name:"with_finally nested raise" (fun _ ->
      let inner_first = ref false in
      let inner_finally = ref false in
      let outer_finally = ref false in
      let start = Fut.Promise.create () in
      let fut =
        let open Fut.Infix_monad in
        Fut_comb.with_finally
          (fun () ->
            Fut_comb.with_finally
              (fun () -> Fut.Promise.future start >>= fun () -> raise (Failure "fail"))
              ~finally:(fun () ->
                if not !outer_finally then (
                  inner_first := true;
                  inner_finally := true);
                Fut.return ()))
          ~finally:(fun () ->
            outer_finally := true;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set start ()) dummy_state);
      assert !inner_first;
      assert !outer_finally)

let with_finally_nested_abort =
  Oth.test ~name:"with_finally nested abort" (fun _ ->
      let inner_first = ref false in
      let inner_finally = ref false in
      let outer_finally = ref false in
      let start = Fut.Promise.create () in
      let fut =
        let open Fut.Infix_monad in
        Fut_comb.with_finally
          (fun () ->
            Fut_comb.with_finally
              (fun () -> Fut.Promise.future start)
              ~finally:(fun () ->
                if not !outer_finally then (
                  inner_first := true;
                  inner_finally := true);
                Fut.return ()))
          ~finally:(fun () ->
            outer_finally := true;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state Fut.(abort (Promise.future start)) dummy_state);
      assert !inner_first;
      assert !outer_finally;
      assert (Fut.state fut = `Aborted))

let with_finally_nested_abort_outside =
  Oth.test ~name:"with_finally nested abort outside" (fun _ ->
      let inner_first = ref false in
      let inner_finally = ref false in
      let outer_finally = ref false in
      let start = Fut.Promise.create () in
      let fut =
        let open Fut.Infix_monad in
        Fut_comb.with_finally
          (fun () ->
            Fut_comb.with_finally
              (fun () -> Fut.Promise.future start)
              ~finally:(fun () ->
                if not !outer_finally then (
                  inner_first := true;
                  inner_finally := true);
                Fut.return ()))
          ~finally:(fun () ->
            outer_finally := true;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.abort fut) dummy_state);
      assert !inner_first;
      assert !outer_finally;
      assert (Fut.state fut = `Aborted))

let with_finally_nested_abort_sequenced =
  Oth.test ~name:"with_finally nested abort sequenced" (fun _ ->
      let inner_first = ref false in
      let inner_finally = ref false in
      let outer_finally = ref false in
      let start = Fut.Promise.create () in
      let trigger_inner = Fut.Promise.create () in
      let fut =
        let open Fut.Infix_monad in
        Fut_comb.with_finally
          (fun () ->
            Fut_comb.with_finally
              (fun () -> Fut.Promise.future start)
              ~finally:(fun () ->
                Fut.Promise.future trigger_inner
                >>= fun () ->
                if not !outer_finally then (
                  inner_first := true;
                  inner_finally := true);
                Fut.return ()))
          ~finally:(fun () ->
            outer_finally := true;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.abort fut) dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set trigger_inner ()) dummy_state);
      assert !inner_first;
      assert !outer_finally;
      assert (Fut.state (Fut.Promise.future start) = `Aborted);
      assert (Fut.state (Fut.Promise.future trigger_inner) = `Det ());
      assert (Fut.state fut = `Aborted))

let with_finally_nested_exn_sequenced =
  Oth.test ~name:"with_finally nested exn sequenced" (fun _ ->
      let inner_first = ref false in
      let inner_finally = ref false in
      let outer_finally = ref false in
      let start = Fut.Promise.create () in
      let wait = Fut.Promise.create () in
      let trigger_inner = Fut.Promise.create () in
      let business_end =
        let open Fut.Infix_monad in
        Fut_comb.with_finally
          (fun () ->
            Fut_comb.with_finally
              (fun () -> Fut.Promise.future wait)
              ~finally:(fun () ->
                Fut.Promise.future trigger_inner
                >>= fun () ->
                if not !outer_finally then (
                  inner_first := true;
                  inner_finally := true);
                Fut.return ()))
          ~finally:(fun () ->
            outer_finally := true;
            Fut.return ())
      in
      let fut =
        Fut.Infix_app.(
          (fun _ _ -> ())
          <$> (let open Fut.Infix_monad in
               Fut.Promise.future start >>= fun () -> failwith "exn")
          <*> business_end)
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set start ()) dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set trigger_inner ()) dummy_state);
      assert !inner_first;
      assert !outer_finally;
      (match Fut.state fut with
      | `Aborted -> assert false
      | `Det _ -> assert false
      | `Undet -> assert false
      | `Exn (Failure _, _) -> ()
      | `Exn _ -> assert false);
      match Fut.state business_end with
      | `Aborted -> assert false
      | `Det _ -> assert false
      | `Undet -> assert false
      | `Exn (Failure _, _) -> ()
      | `Exn _ -> assert false)

let on_failure_success =
  Oth.test ~desc:"Test the failure block is not run on success" ~name:"on_failure success" (fun _ ->
      let failure_exec = ref 0 in
      let p = Fut.Promise.create () in
      let fut =
        Fut_comb.on_failure
          (fun () -> Fut.Promise.future p)
          ~failure:(fun () ->
            incr failure_exec;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set p ()) dummy_state);
      assert (!failure_exec = 0);
      assert (Fut.state fut = `Det ()))

let on_failure_aborted =
  Oth.test ~desc:"Test the failure block is run on abort" ~name:"on_failure aborted" (fun _ ->
      let failure_exec = ref 0 in
      let p = Fut.Promise.create () in
      let fut =
        Fut_comb.on_failure
          (fun () -> Fut.Promise.future p)
          ~failure:(fun () ->
            incr failure_exec;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.abort (Fut.Promise.future p)) dummy_state);
      assert (!failure_exec > 0);
      assert (!failure_exec = 1);
      assert (Fut.state fut = `Aborted))

let on_failure_aborted_from_outside =
  Oth.test
    ~desc:"Test the failure block is run on abort from the outside"
    ~name:"on_failure aborted outside"
    (fun _ ->
      let failure_exec = ref 0 in
      let p = Fut.Promise.create () in
      let fut =
        Fut_comb.on_failure
          (fun () -> Fut.Promise.future p)
          ~failure:(fun () ->
            incr failure_exec;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.abort fut) dummy_state);
      assert (!failure_exec > 0);
      assert (!failure_exec = 1);
      assert (Fut.state fut = `Aborted);
      assert (Fut.state (Fut.Promise.future p) = `Aborted))

let on_failure_exn =
  Oth.test
    ~desc:"Test the failure block is run on a fut determining to an exn"
    ~name:"on_failure exn"
    (fun _ ->
      let failure_exec = ref 0 in
      let p = Fut.Promise.create () in
      let fut =
        Fut_comb.on_failure
          (fun () -> Fut.Promise.future p)
          ~failure:(fun () ->
            incr failure_exec;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set_exn p (Failure "foo", None)) dummy_state);
      assert (!failure_exec > 0);
      assert (!failure_exec = 1);
      match Fut.state fut with
      | `Exn (Failure _, None) -> ()
      | _ -> assert false)

let on_failure_raise =
  Oth.test
    ~desc:"Test the failure block is run on raising in the function"
    ~name:"on_failure raise"
    (fun _ ->
      let failure_exec = ref 0 in
      let fut =
        Fut_comb.on_failure
          (fun () -> failwith "foo")
          ~failure:(fun () ->
            incr failure_exec;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      assert (!failure_exec > 0);
      assert (!failure_exec = 1);
      match Fut.state fut with
      | `Exn (Failure _, Some _) -> ()
      | _ -> assert false)

let timeout_timeout =
  Oth.test ~desc:"Test timeout when the timeout function fires" ~name:"timeout timeout" (fun _ ->
      let timeout = Fut.Promise.create () in
      let call = Fut.Promise.create () in
      let wait = Fut_comb.timeout ~timeout:(Fut.Promise.future timeout) (Fut.Promise.future call) in
      ignore (Fut.run_with_state wait dummy_state);
      assert (Fut.state wait = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set timeout ()) dummy_state);
      assert (Fut.state wait = `Det `Timeout);
      assert (Fut.state (Fut.Promise.future call) = `Aborted))

let timeout_success =
  Oth.test ~desc:"Test timeout when the operation succeeds" ~name:"timeout success" (fun _ ->
      let timeout = Fut.Promise.create () in
      let call = Fut.Promise.create () in
      let wait = Fut_comb.timeout ~timeout:(Fut.Promise.future timeout) (Fut.Promise.future call) in
      ignore (Fut.run_with_state wait dummy_state);
      assert (Fut.state wait = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set call ()) dummy_state);
      assert (Fut.state wait = `Det (`Ok ()));
      assert (Fut.state (Fut.Promise.future timeout) = `Aborted))

let protect_test =
  Oth.test ~name:"protect" (fun _ ->
      let protected = Fut.Promise.create () in
      let trigger = Fut.Promise.create () in
      let fut =
        Fut_comb.protect (fun () ->
            let open Fut.Infix_monad in
            Fut.Promise.future trigger >>= fun () -> Fut.Promise.set protected ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.abort fut) dummy_state);
      assert (Fut.state fut = `Aborted);
      assert (Fut.state (Fut.Promise.future protected) = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set trigger ()) dummy_state);
      assert (Fut.state (Fut.Promise.future protected) = `Det ()))

let protect_fork_finally_abort_in_protect_test =
  Oth.test ~name:"protect fork_finally pattern abort in protect" (fun _ ->
      let hit_finally = ref false in
      let protected = Fut.Promise.create () in
      let trigger1 = Fut.Promise.create () in
      let trigger2 = Fut.Promise.create () in
      let fut =
        let open Fut.Infix_monad in
        Fut_comb.protect (fun () ->
            Fut.Promise.future trigger1
            >>= fun () ->
            Fut.fork
              (Fut_comb.with_finally
                 (fun () -> Fut.Promise.future trigger2 >>= fun () -> Fut.Promise.set protected ())
                 ~finally:(fun () ->
                   hit_finally := true;
                   Fut.return ())))
        >>= fun fut -> fut
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.abort fut) dummy_state);
      assert (Fut.state fut = `Aborted);
      assert (Fut.state (Fut.Promise.future protected) = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set trigger1 ()) dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set trigger2 ()) dummy_state);
      assert (Fut.state (Fut.Promise.future protected) = `Det ());
      assert !hit_finally)

let protect_fork_finally_abort_in_finally_test =
  Oth.test ~name:"protect fork_finally pattern abort in finally" (fun _ ->
      let hit_finally = ref false in
      let protected = Fut.Promise.create () in
      let trigger1 = Fut.Promise.create () in
      let trigger2 = Fut.Promise.create () in
      let fut =
        let open Fut.Infix_monad in
        Fut_comb.protect (fun () ->
            Fut.Promise.future trigger1
            >>= fun () ->
            Fut.fork
              (Fut_comb.with_finally
                 (fun () -> Fut.Promise.future trigger2 >>= fun () -> Fut.Promise.set protected ())
                 ~finally:(fun () ->
                   hit_finally := true;
                   Fut.return ())))
        >>= fun fut -> fut
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set trigger1 ()) dummy_state);
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.abort fut) dummy_state);
      assert (Fut.state fut = `Aborted);
      assert (Fut.state (Fut.Promise.future protected) = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set trigger2 ()) dummy_state);
      assert (Fut.state (Fut.Promise.future protected) = `Undet);
      assert !hit_finally)

let protect_fork_finally_abort_in_on_failure_test =
  Oth.test ~name:"protect fork_on_failure pattern abort in on_failure" (fun _ ->
      let hit_failure = ref false in
      let protected = Fut.Promise.create () in
      let trigger1 = Fut.Promise.create () in
      let trigger2 = Fut.Promise.create () in
      let fut =
        let open Fut.Infix_monad in
        Fut_comb.protect (fun () ->
            Fut.Promise.future trigger1
            >>= fun () ->
            Fut.fork
              (Fut_comb.on_failure
                 (fun () -> Fut.Promise.future trigger2 >>= fun () -> Fut.Promise.set protected ())
                 ~failure:(fun () ->
                   hit_failure := true;
                   Fut.return ())))
        >>= fun fut -> fut
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set trigger1 ()) dummy_state);
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.abort fut) dummy_state);
      assert (Fut.state fut = `Aborted);
      assert (Fut.state (Fut.Promise.future protected) = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set trigger2 ()) dummy_state);
      assert (Fut.state (Fut.Promise.future protected) = `Undet);
      assert !hit_failure)

let protect_finally_abort_in_protect_test =
  Oth.test ~name:"protect_finally abort in protect" (fun _ ->
      let hit_finally = ref false in
      let protected = Fut.Promise.create () in
      let trigger1 = Fut.Promise.create () in
      let trigger2 = Fut.Promise.create () in
      let fut =
        let open Fut.Infix_monad in
        Fut_comb.protect_finally
          ~setup:(fun () -> Fut.Promise.future trigger1)
          (fun () -> Fut.Promise.future trigger2 >>= fun () -> Fut.Promise.set protected ())
          ~finally:(fun () ->
            hit_finally := true;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.abort fut) dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set trigger1 ()) dummy_state);
      ignore (Fut.run_with_state fut dummy_state);
      assert (Fut.state fut = `Aborted);
      assert (Fut.state (Fut.Promise.future protected) = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set trigger2 ()) dummy_state);
      assert (Fut.state (Fut.Promise.future protected) = `Undet);
      assert !hit_finally)

let protect_finally_abort_in_body_test =
  Oth.test ~name:"protect_finally abort in body" (fun _ ->
      let hit_finally = ref false in
      let protected = Fut.Promise.create () in
      let trigger1 = Fut.Promise.create () in
      let trigger2 = Fut.Promise.create () in
      let fut =
        let open Fut.Infix_monad in
        Fut_comb.protect_finally
          ~setup:(fun () -> Fut.Promise.future trigger1)
          (fun () -> Fut.Promise.future trigger2 >>= fun () -> Fut.Promise.set protected ())
          ~finally:(fun () ->
            hit_finally := true;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set trigger1 ()) dummy_state);
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.abort fut) dummy_state);
      assert (Fut.state fut = `Aborted);
      assert (Fut.state (Fut.Promise.future protected) = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set trigger2 ()) dummy_state);
      assert (Fut.state (Fut.Promise.future protected) = `Undet);
      assert !hit_finally)

let protect_finally_exn_in_body_test =
  Oth.test ~name:"protect_finally exn in body" (fun _ ->
      let hit_finally = ref false in
      let trigger1 = Fut.Promise.create () in
      let trigger2 = Fut.Promise.create () in
      let fut =
        let open Fut.Infix_monad in
        Fut_comb.protect_finally
          ~setup:(fun () -> Fut.Promise.future trigger1)
          (fun () -> Fut.Promise.future trigger2 >>= fun () -> raise (Failure "foo"))
          ~finally:(fun () ->
            hit_finally := true;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set trigger1 ()) dummy_state);
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set trigger2 ()) dummy_state);
      (match Fut.state fut with
      | `Exn _ -> ()
      | `Undet -> assert false
      | `Det _ -> assert false
      | `Aborted -> assert false);
      assert !hit_finally)

let protect_finally_abort_in_finally_test =
  Oth.test ~name:"protect_finally abort in finally" (fun _ ->
      let hit_finally = ref false in
      let protected = Fut.Promise.create () in
      let trigger1 = Fut.Promise.create () in
      let trigger2 = Fut.Promise.create () in
      let trigger3 = Fut.Promise.create () in
      let fut =
        let open Fut.Infix_monad in
        Fut_comb.protect_finally
          ~setup:(fun () -> Fut.Promise.future trigger1)
          (fun () -> Fut.Promise.future trigger2 >>= fun () -> Fut.Promise.set protected ())
          ~finally:(fun () ->
            Fut.Promise.future trigger3
            >>= fun () ->
            hit_finally := true;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set trigger1 ()) dummy_state);
      ignore (Fut.run_with_state fut dummy_state);
      assert (Fut.state (Fut.Promise.future protected) = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set trigger2 ()) dummy_state);
      assert (Fut.state (Fut.Promise.future protected) = `Det ());
      ignore (Fut.run_with_state (Fut.abort fut) dummy_state);
      assert (Fut.state fut = `Aborted);
      ignore (Fut.run_with_state (Fut.Promise.set trigger3 ()) dummy_state);
      assert !hit_finally)

let protect_finally_success_test =
  Oth.test ~name:"protect_finally success" (fun _ ->
      let hit_finally = ref false in
      let protected = Fut.Promise.create () in
      let trigger1 = Fut.Promise.create () in
      let trigger2 = Fut.Promise.create () in
      let fut =
        let open Fut.Infix_monad in
        Fut_comb.protect_finally
          ~setup:(fun () -> Fut.Promise.future trigger1)
          (fun () -> Fut.Promise.future trigger2 >>= fun () -> Fut.Promise.set protected ())
          ~finally:(fun () ->
            hit_finally := true;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set trigger1 ()) dummy_state);
      ignore (Fut.run_with_state fut dummy_state);
      assert (Fut.state (Fut.Promise.future protected) = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set trigger2 ()) dummy_state);
      assert (Fut.state (Fut.Promise.future protected) = `Det ());
      assert (Fut.state fut = `Det ());
      assert !hit_finally)

let () =
  Oth.(
    run
      (parallel
         [
           first1;
           first2;
           first3;
           firstl1;
           firstl2;
           firstl3;
           map1;
           map2;
           firstl4;
           first4;
           with_finally_success;
           with_finally_aborted;
           with_finally_aborted_complete;
           with_finally_exn;
           with_finally_raise;
           with_finally_exn_in_finally;
           with_finally_exn_in_body_and_finally;
           with_finally_aborted_from_outside;
           with_finally_nested_raise;
           with_finally_nested_abort;
           with_finally_nested_abort_outside;
           with_finally_nested_abort_sequenced;
           with_finally_nested_exn_sequenced;
           on_failure_success;
           on_failure_aborted;
           on_failure_aborted_from_outside;
           on_failure_exn;
           on_failure_raise;
           timeout_timeout;
           timeout_success;
           protect_test;
           protect_fork_finally_abort_in_protect_test;
           protect_fork_finally_abort_in_finally_test;
           protect_fork_finally_abort_in_on_failure_test;
           protect_finally_abort_in_protect_test;
           protect_finally_abort_in_body_test;
           protect_finally_exn_in_body_test;
           protect_fork_finally_abort_in_finally_test;
           protect_finally_success_test;
         ]))
