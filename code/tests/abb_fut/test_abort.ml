module Fut = Abb_fut.Make (struct
  type t = unit
end)

open Fut.Infix_monad
open Fut.Infix_app

exception Foo

let test1 =
  Oth.test ~desc:"Aborting a future aborts it" ~name:"Abort #1" (fun _ ->
      let state = Abb_fut.State.create () in
      let p1 = Fut.Promise.create () in
      let fut = Fut.Promise.future p1 in
      ignore (fut >>| Printf.printf "Hi, %s\n");
      ignore (Fut.run_with_state (Fut.abort fut) state);
      assert (Fut.state fut = `Aborted))

let test2 =
  Oth.test
    ~desc:"Aborting the least dependent future aborts all dependents"
    ~name:"Abort #2"
    (fun _ ->
      let state = Abb_fut.State.create () in
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = fut1 >>| fun s -> "Hi, " ^ s in
      let fut3 = fut2 >>| fun s -> Printf.printf "You said: %s\n" s in
      ignore (Fut.run_with_state (Fut.abort fut3) state);
      assert (Fut.state fut1 = `Aborted);
      assert (Fut.state fut2 = `Aborted);
      assert (Fut.state fut3 = `Aborted))

let test3 =
  Oth.test
    ~desc:"Aborting the middle future aborts watchers and dependents"
    ~name:"Abort #3"
    (fun _ ->
      let state = Abb_fut.State.create () in
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = fut1 >>| fun s -> "Hi, " ^ s in
      let fut3 = fut2 >>| fun s -> Printf.printf "You said: %s\n" s in
      ignore (Fut.run_with_state (Fut.abort fut2) state);
      assert (Fut.state fut1 = `Aborted);
      assert (Fut.state fut2 = `Aborted);
      assert (Fut.state fut3 = `Aborted))

let test4 =
  Oth.test ~desc:"Aborting the most dependent future aborts all" ~name:"Abort #4" (fun _ ->
      let state = Abb_fut.State.create () in
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = fut1 >>| fun s -> "Hi, " ^ s in
      let fut3 = fut2 >>| fun s -> Printf.printf "You said: %s\n" s in
      ignore (Fut.run_with_state (Fut.abort fut1) state);
      assert (Fut.state fut1 = `Aborted);
      assert (Fut.state fut2 = `Aborted);
      assert (Fut.state fut3 = `Aborted))

let test5 =
  Oth.test ~desc:"Aborting works when bound to" ~name:"Abort #5" (fun _ ->
      let state = Abb_fut.State.create () in
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = fut1 >>| fun s -> "Hi, " ^ s in
      let fut3 = fut2 >>| fun s -> Printf.printf "You said: %s\n" s in
      ignore (Fut.run_with_state (Fut.abort fut3) state);
      assert (Fut.state fut1 = `Aborted);
      assert (Fut.state fut2 = `Aborted);
      assert (Fut.state fut3 = `Aborted))

let test6 =
  Oth.test ~desc:"Aborting a partially applied applicative" ~name:"Abort #6" (fun _ ->
      let state = Abb_fut.State.create () in
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = Fut.Promise.future p2 in
      let r = ref 0 in
      let both v1 =
        r := !r + 1;
        fun v2 ->
          r := !r + 1;
          (v1, v2)
      in
      let fut3 =
        both
        <$> fut1
        <*> fut2
        >>| fun (v1, v2) ->
        assert (v1 = 1);
        assert (v2 = 2)
      in
      ignore (Fut.run_with_state fut3 state);
      ignore (Fut.run_with_state (Fut.Promise.set p1 1) state);
      assert (!r = 1);
      ignore (Fut.run_with_state (Fut.abort fut2) state);
      assert (!r = 1);
      assert (Fut.state fut3 = `Aborted);
      assert (Fut.state fut2 = `Aborted);
      assert (Fut.state fut1 = `Det 1))

let test7 =
  Oth.test ~desc:"Setting an aborted future is a no-op" ~name:"Abort #7" (fun _ ->
      let state = Abb_fut.State.create () in
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = Fut.Promise.future p2 in
      let r = ref 0 in
      let both v1 =
        r := !r + 1;
        fun v2 ->
          r := !r + 1;
          (v1, v2)
      in
      let fut3 =
        both
        <$> fut1
        <*> fut2
        >>| fun (v1, v2) ->
        assert (v1 = 1);
        assert (v2 = 2)
      in
      ignore (Fut.run_with_state fut3 state);
      ignore (Fut.run_with_state (Fut.Promise.set p1 1) state);
      assert (!r = 1);
      ignore (Fut.run_with_state (Fut.abort fut2) state);
      ignore (Fut.run_with_state (Fut.Promise.set p2 2) state);
      assert (!r = 1);
      assert (Fut.state fut3 = `Aborted);
      assert (Fut.state fut2 = `Aborted);
      assert (Fut.state fut1 = `Det 1))

let test8 =
  Oth.test ~desc:"Await evaluated if aborted from below" ~name:"Await Abort #1" (fun _ ->
      let state = Abb_fut.State.create () in
      let r = ref false in
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = Fut.await fut1 >>| fun _ -> r := true in
      ignore (Fut.run_with_state (Fut.abort fut1) state);
      assert (Fut.state fut1 = `Aborted);
      assert (Fut.state fut2 = `Det ());
      assert !r)

let test9 =
  Oth.test ~desc:"Await not evaluated if aborted from above" ~name:"Await Abort #2" (fun _ ->
      let state = Abb_fut.State.create () in
      let r = ref false in
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = Fut.await fut1 >>| fun _ -> r := true in
      ignore (Fut.run_with_state (Fut.abort fut2) state);
      assert (Fut.state fut1 = `Aborted);
      assert (Fut.state fut2 = `Aborted);
      assert (not !r))

let test10 =
  Oth.test ~desc:"Validate that the abort function gets called on abort" ~name:"Abort #8" (fun _ ->
      let state = Abb_fut.State.create () in
      let r = ref false in
      let p1 =
        Fut.Promise.create
          ~abort:(fun () ->
            r := true;
            Fut.return ())
          ()
      in
      let fut = Fut.Promise.future p1 in
      ignore (fut >>| Printf.printf "Hi, %s\n");
      ignore (Fut.run_with_state (Fut.abort fut) state);
      assert (Fut.state fut = `Aborted);
      assert !r)

let test11 =
  Oth.test ~desc:"Test abort with a applicatives" ~name:"Abort #9" (fun _ ->
      let state = Abb_fut.State.create () in
      let executed_anyways = ref false in
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = Fut.Promise.future p2 in
      let fut3 = fut2 >>| fun _ -> () in
      let both v1 v2 = (v1, v2) in
      let fut4 = both <$> fut1 <*> fut3 >>| fun (v1, v2) -> executed_anyways := true in
      let fut4 = Fut.await fut4 in
      ignore (Fut.run_with_state fut4 state);
      ignore (Fut.run_with_state (Fut.abort fut2) state);
      assert (not !executed_anyways);
      assert (Fut.state fut4 = `Det `Aborted);
      assert (Fut.state fut1 = `Aborted);
      assert (Fut.state fut2 = `Aborted);
      assert (Fut.state fut3 = `Aborted))

let test12 =
  Oth.test ~desc:"Test abort with a applicatives" ~name:"Abort #10" (fun _ ->
      let state = Abb_fut.State.create () in
      let executed_anyways = ref false in
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = Fut.Promise.future p2 in
      let fut3 = fut2 >>| fun _ -> () in
      let both v1 v2 = (v1, v2) in
      let fut4 = Fut.app (Fut.app (Fut.return both) fut1) fut3 in
      let fut4 = Fut.await fut4 in
      ignore (Fut.run_with_state fut4 state);
      ignore (Fut.run_with_state (Fut.abort fut1) state);
      assert (not !executed_anyways);
      assert (Fut.state fut1 = `Aborted);
      assert (Fut.state fut2 = `Aborted);
      assert (Fut.state fut3 = `Aborted);
      assert (Fut.state fut4 = `Det `Aborted))

let test13 =
  Oth.test ~desc:"Await bind evaluated if aborted from below" ~name:"Await Bind Abort #1" (fun _ ->
      let state = Abb_fut.State.create () in
      let r = ref false in
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 =
        Fut.await_bind
          (fun _ ->
            r := true;
            Fut.return ())
          fut1
      in
      ignore (Fut.run_with_state (Fut.abort fut2) state);
      assert (Fut.state fut1 = `Aborted);
      assert (Fut.state fut2 = `Aborted);
      assert (not !r))

let test14 =
  Oth.test ~desc:"Await bind evaluated if aborted from above" ~name:"Await Bind Abort #2" (fun _ ->
      let state = Abb_fut.State.create () in
      let r = ref false in
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 =
        Fut.await_bind
          (fun _ ->
            r := true;
            Fut.return ())
          fut1
      in
      ignore (Fut.run_with_state (Fut.abort fut1) state);
      assert (Fut.state fut1 = `Aborted);
      assert (Fut.state fut2 = `Det ());
      assert !r)

let test15 =
  Oth.test ~desc:"Await bind fails when it throws exn" ~name:"Await Bind Exn #1" (fun _ ->
      let state = Abb_fut.State.create () in
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = Fut.await_bind (fun _ -> failwith "fail") fut1 in
      ignore (Fut.run_with_state (Fut.abort fut1) state);
      assert (Fut.state fut1 = `Aborted);
      match Fut.state fut2 with
        | `Det _ | `Aborted | `Undet -> assert false
        | `Exn _                     -> ())

let () =
  Oth.(
    run
      (parallel
         [
           test1;
           test2;
           test3;
           test4;
           test5;
           test6;
           test7;
           test8;
           test9;
           test10;
           test11;
           test12;
           test13;
           test14;
           test15;
         ]))
