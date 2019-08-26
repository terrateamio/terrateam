module Fut = Abb_fut.Make (struct
  type t = unit
end)
open Fut.Infix_monad
open Fut.Infix_app
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
        | `Det (v, fut)              ->
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
        | `Det (v, fut)              -> (
            assert (v = 1);
            match Fut.state fut with
              | `Det v                     -> assert (v = 2)
              | `Undet | `Aborted | `Exn _ -> assert false )
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
        | `Det (v, [ fut ])          ->
            assert (v = 1);
            assert (Fut.state fut = `Undet)
        | `Det _                     -> assert false
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
        | `Det (v, [ fut ])          -> (
            assert (v = 1);
            match Fut.state fut with
              | `Det v                     -> assert (v = 2)
              | `Undet | `Aborted | `Exn _ -> assert false )
        | `Det _                     -> assert false
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
      let finally_exec = ref false in
      let p = Fut.Promise.create () in
      let fut =
        Fut_comb.with_finally
          (fun () -> Fut.Promise.future p)
          ~finally:(fun () ->
            finally_exec := true;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set p ()) dummy_state);
      assert !finally_exec;
      assert (Fut.state fut = `Det ()))

let with_finally_aborted =
  Oth.test ~desc:"Test the finally block is run on abort" ~name:"with_finally aborted" (fun _ ->
      let finally_exec = ref false in
      let p = Fut.Promise.create () in
      let fut =
        Fut_comb.with_finally
          (fun () -> Fut.Promise.future p)
          ~finally:(fun () ->
            finally_exec := true;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.abort (Fut.Promise.future p)) dummy_state);
      assert !finally_exec;
      assert (Fut.state fut = `Aborted))

let with_finally_exn =
  Oth.test
    ~desc:"Test the finally block is run on a fut determining to an exn"
    ~name:"with_finally exn"
    (fun _ ->
      let finally_exec = ref false in
      let p = Fut.Promise.create () in
      let fut =
        Fut_comb.with_finally
          (fun () -> Fut.Promise.future p)
          ~finally:(fun () ->
            finally_exec := true;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set_exn p (Failure "foo", None)) dummy_state);
      assert !finally_exec;
      match Fut.state fut with
        | `Exn (Failure _, None) -> ()
        | _                      -> assert false)

let with_finally_raise =
  Oth.test
    ~desc:"Test the finally block is run on raising in the function"
    ~name:"with_finally raise"
    (fun _ ->
      let finally_exec = ref false in
      let fut =
        Fut_comb.with_finally
          (fun () -> failwith "foo")
          ~finally:(fun () ->
            finally_exec := true;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      assert !finally_exec;
      match Fut.state fut with
        | `Exn (Failure _, Some _) -> ()
        | _                        -> assert false)

let with_finally_aborted_from_outside =
  Oth.test
    ~desc:"Test the finally block is run on abort from the outside"
    ~name:"with_finally aborted outside"
    (fun _ ->
      let finally_exec = ref false in
      let p = Fut.Promise.create () in
      let fut =
        Fut_comb.with_finally
          (fun () -> Fut.Promise.future p)
          ~finally:(fun () ->
            finally_exec := true;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.abort fut) dummy_state);
      assert !finally_exec;
      assert (Fut.state fut = `Aborted);
      assert (Fut.state (Fut.Promise.future p) = `Aborted))

let on_failure_success =
  Oth.test ~desc:"Test the failure block is not run on success" ~name:"on_failure success" (fun _ ->
      let failure_exec = ref false in
      let p = Fut.Promise.create () in
      let fut =
        Fut_comb.on_failure
          (fun () -> Fut.Promise.future p)
          ~failure:(fun () ->
            failure_exec := true;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set p ()) dummy_state);
      assert (not !failure_exec);
      assert (Fut.state fut = `Det ()))

let on_failure_aborted =
  Oth.test ~desc:"Test the failure block is run on abort" ~name:"on_failure aborted" (fun _ ->
      let failure_exec = ref false in
      let p = Fut.Promise.create () in
      let fut =
        Fut_comb.on_failure
          (fun () -> Fut.Promise.future p)
          ~failure:(fun () ->
            failure_exec := true;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.abort (Fut.Promise.future p)) dummy_state);
      assert !failure_exec;
      assert (Fut.state fut = `Aborted))

let on_failure_aborted_from_outside =
  Oth.test
    ~desc:"Test the failure block is run on abort from the outside"
    ~name:"on_failure aborted outside"
    (fun _ ->
      let failure_exec = ref false in
      let p = Fut.Promise.create () in
      let fut =
        Fut_comb.on_failure
          (fun () -> Fut.Promise.future p)
          ~failure:(fun () ->
            failure_exec := true;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.abort fut) dummy_state);
      assert !failure_exec;
      assert (Fut.state fut = `Aborted);
      assert (Fut.state (Fut.Promise.future p) = `Aborted))

let on_failure_exn =
  Oth.test
    ~desc:"Test the failure block is run on a fut determining to an exn"
    ~name:"on_failure exn"
    (fun _ ->
      let failure_exec = ref false in
      let p = Fut.Promise.create () in
      let fut =
        Fut_comb.on_failure
          (fun () -> Fut.Promise.future p)
          ~failure:(fun () ->
            failure_exec := true;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set_exn p (Failure "foo", None)) dummy_state);
      assert !failure_exec;
      match Fut.state fut with
        | `Exn (Failure _, None) -> ()
        | _                      -> assert false)

let on_failure_raise =
  Oth.test
    ~desc:"Test the failure block is run on raising in the function"
    ~name:"on_failure raise"
    (fun _ ->
      let failure_exec = ref false in
      let fut =
        Fut_comb.on_failure
          (fun () -> failwith "foo")
          ~failure:(fun () ->
            failure_exec := true;
            Fut.return ())
      in
      ignore (Fut.run_with_state fut dummy_state);
      assert !failure_exec;
      match Fut.state fut with
        | `Exn (Failure _, Some _) -> ()
        | _                        -> assert false)

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
           with_finally_exn;
           with_finally_raise;
           with_finally_aborted_from_outside;
           on_failure_success;
           on_failure_aborted;
           on_failure_aborted_from_outside;
           on_failure_exn;
           on_failure_raise;
         ]))
