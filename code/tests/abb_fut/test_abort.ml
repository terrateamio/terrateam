module Fut = Abb_fut.Make (struct
  type data = unit

  let zero_data = ()

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
      Oth.Assert.true_ "Fut.state fut = `Aborted" (Fut.state fut = `Aborted))

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
      Oth.Assert.true_ "Fut.state fut1 = `Aborted" (Fut.state fut1 = `Aborted);
      Oth.Assert.true_ "Fut.state fut2 = `Aborted" (Fut.state fut2 = `Aborted);
      Oth.Assert.true_ "Fut.state fut3 = `Aborted" (Fut.state fut3 = `Aborted))

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
      Oth.Assert.true_ "Fut.state fut1 = `Aborted" (Fut.state fut1 = `Aborted);
      Oth.Assert.true_ "Fut.state fut2 = `Aborted" (Fut.state fut2 = `Aborted);
      Oth.Assert.true_ "Fut.state fut3 = `Aborted" (Fut.state fut3 = `Aborted))

let test4 =
  Oth.test ~desc:"Aborting the most dependent future aborts all" ~name:"Abort #4" (fun _ ->
      let state = Abb_fut.State.create () in
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = fut1 >>| fun s -> "Hi, " ^ s in
      let fut3 = fut2 >>| fun s -> Printf.printf "You said: %s\n" s in
      ignore (Fut.run_with_state (Fut.abort fut1) state);
      Oth.Assert.true_ "Fut.state fut1 = `Aborted" (Fut.state fut1 = `Aborted);
      Oth.Assert.true_ "Fut.state fut2 = `Aborted" (Fut.state fut2 = `Aborted);
      Oth.Assert.true_ "Fut.state fut3 = `Aborted" (Fut.state fut3 = `Aborted))

let test5 =
  Oth.test ~desc:"Aborting works when bound to" ~name:"Abort #5" (fun _ ->
      let state = Abb_fut.State.create () in
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = fut1 >>| fun s -> "Hi, " ^ s in
      let fut3 = fut2 >>| fun s -> Printf.printf "You said: %s\n" s in
      ignore (Fut.run_with_state (Fut.abort fut3) state);
      Oth.Assert.true_ "Fut.state fut1 = `Aborted" (Fut.state fut1 = `Aborted);
      Oth.Assert.true_ "Fut.state fut2 = `Aborted" (Fut.state fut2 = `Aborted);
      Oth.Assert.true_ "Fut.state fut3 = `Aborted" (Fut.state fut3 = `Aborted))

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
        Oth.Assert.Eq.int ~expected:1 ~actual:v1;
        Oth.Assert.Eq.int ~expected:2 ~actual:v2
      in
      ignore (Fut.run_with_state fut3 state);
      ignore (Fut.run_with_state (Fut.Promise.set p1 1) state);
      Oth.Assert.Eq.int ~expected:1 ~actual:!r;
      ignore (Fut.run_with_state (Fut.abort fut2) state);
      Oth.Assert.Eq.int ~expected:1 ~actual:!r;
      Oth.Assert.true_ "Fut.state fut3 = `Aborted" (Fut.state fut3 = `Aborted);
      Oth.Assert.true_ "Fut.state fut2 = `Aborted" (Fut.state fut2 = `Aborted);
      Oth.Assert.true_ "Fut.state fut1 = `Det 1" (Fut.state fut1 = `Det 1))

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
        Oth.Assert.Eq.int ~expected:1 ~actual:v1;
        Oth.Assert.Eq.int ~expected:2 ~actual:v2
      in
      ignore (Fut.run_with_state fut3 state);
      ignore (Fut.run_with_state (Fut.Promise.set p1 1) state);
      Oth.Assert.Eq.int ~expected:1 ~actual:!r;
      ignore (Fut.run_with_state (Fut.abort fut2) state);
      ignore (Fut.run_with_state (Fut.Promise.set p2 2) state);
      Oth.Assert.Eq.int ~expected:1 ~actual:!r;
      Oth.Assert.true_ "Fut.state fut3 = `Aborted" (Fut.state fut3 = `Aborted);
      Oth.Assert.true_ "Fut.state fut2 = `Aborted" (Fut.state fut2 = `Aborted);
      Oth.Assert.true_ "Fut.state fut1 = `Det 1" (Fut.state fut1 = `Det 1))

let test8 =
  Oth.test ~desc:"Await evaluated if aborted from below" ~name:"Await Abort #1" (fun _ ->
      let state = Abb_fut.State.create () in
      let r = ref false in
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = Fut.await fut1 >>| fun _ -> r := true in
      ignore (Fut.run_with_state (Fut.abort fut1) state);
      Oth.Assert.true_ "Fut.state fut1 = `Aborted" (Fut.state fut1 = `Aborted);
      Oth.Assert.true_ "Fut.state fut2 = `Det ()" (Fut.state fut2 = `Det ());
      Oth.Assert.true_ "!r" !r)

let test9 =
  Oth.test ~desc:"Await not evaluated if aborted from above" ~name:"Await Abort #2" (fun _ ->
      let state = Abb_fut.State.create () in
      let r = ref false in
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = Fut.await fut1 >>| fun _ -> r := true in
      ignore (Fut.run_with_state (Fut.abort fut2) state);
      Oth.Assert.true_ "Fut.state fut1 = `Aborted" (Fut.state fut1 = `Aborted);
      Oth.Assert.true_ "Fut.state fut2 = `Aborted" (Fut.state fut2 = `Aborted);
      Oth.Assert.true_ "not !r" (not !r))

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
      Oth.Assert.true_ "Fut.state fut = `Aborted" (Fut.state fut = `Aborted);
      Oth.Assert.true_ "!r" !r)

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
      let fut4 = both <$> fut1 <*> fut3 >>| fun (_v1, _v2) -> executed_anyways := true in
      let fut4 = Fut.await fut4 in
      ignore (Fut.run_with_state fut4 state);
      ignore (Fut.run_with_state (Fut.abort fut2) state);
      Oth.Assert.true_ "not !executed_anyways" (not !executed_anyways);
      Oth.Assert.true_ "Fut.state fut4 = `Det `Aborted" (Fut.state fut4 = `Det `Aborted);
      Oth.Assert.true_ "Fut.state fut1 = `Aborted" (Fut.state fut1 = `Aborted);
      Oth.Assert.true_ "Fut.state fut2 = `Aborted" (Fut.state fut2 = `Aborted);
      Oth.Assert.true_ "Fut.state fut3 = `Aborted" (Fut.state fut3 = `Aborted))

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
      Oth.Assert.true_ "not !executed_anyways" (not !executed_anyways);
      Oth.Assert.true_ "Fut.state fut1 = `Aborted" (Fut.state fut1 = `Aborted);
      Oth.Assert.true_ "Fut.state fut2 = `Aborted" (Fut.state fut2 = `Aborted);
      Oth.Assert.true_ "Fut.state fut3 = `Aborted" (Fut.state fut3 = `Aborted);
      Oth.Assert.true_ "Fut.state fut4 = `Det `Aborted" (Fut.state fut4 = `Det `Aborted))

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
      Oth.Assert.true_ "Fut.state fut1 = `Aborted" (Fut.state fut1 = `Aborted);
      Oth.Assert.true_ "Fut.state fut2 = `Aborted" (Fut.state fut2 = `Aborted);
      Oth.Assert.true_ "!r" !r)

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
      Oth.Assert.true_ "Fut.state fut1 = `Aborted" (Fut.state fut1 = `Aborted);
      Oth.Assert.true_ "Fut.state fut2 = `Det ()" (Fut.state fut2 = `Det ());
      Oth.Assert.true_ "!r" !r)

let test15 =
  Oth.test ~desc:"Await bind fails when it throws exn" ~name:"Await Bind Exn #1" (fun _ ->
      let state = Abb_fut.State.create () in
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = Fut.await_bind (fun _ -> failwith "fail") fut1 in
      ignore (Fut.run_with_state (Fut.abort fut1) state);
      Oth.Assert.true_ "Fut.state fut1 = `Aborted" (Fut.state fut1 = `Aborted);
      match Fut.state fut2 with
      | `Det _ | `Aborted | `Undet -> Oth.Assert.false_ "Await Bind Exn #1: unexpected value"
      | `Exn _ -> ())

let test_cancel =
  Oth.test ~desc:"Canceling a future aborts it" ~name:"Cancel #1" (fun _ ->
      let state = Abb_fut.State.create () in
      let p1 = Fut.Promise.create () in
      let fut = Fut.Promise.future p1 in
      ignore (fut >>| Printf.printf "Hi, %s\n");
      ignore (Fut.run_with_state (Fut.cancel fut) state);
      Oth.Assert.true_ "Fut.state fut = `Aborted" (Fut.state fut = `Aborted))

let test_cancel_deep =
  Oth.test ~desc:"Canceling a future aborts its watchers" ~name:"Cancel #2" (fun _ ->
      let state = Abb_fut.State.create () in
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = fut1 >>| fun s -> "Hi, " ^ s in
      let fut3 = fut2 >>| fun s -> Printf.printf "You said: %s\n" s in
      ignore (Fut.run_with_state (Fut.cancel fut2) state);
      Oth.Assert.true_ "Fut.state fut1 = `Undet" (Fut.state fut1 = `Undet);
      Oth.Assert.true_ "Fut.state fut2 = `Aborted" (Fut.state fut2 = `Aborted);
      Oth.Assert.true_ "Fut.state fut3 = `Aborted" (Fut.state fut3 = `Aborted))

let test_abort_determined_after_completed =
  Oth.test ~name:"Abort determined after completed" (fun _ ->
      let state = Abb_fut.State.create () in
      let trigger_next_step = Fut.Promise.create () in
      let abort () = Fut.Promise.future trigger_next_step in
      let fut = Fut.Promise.(future (create ~abort ())) in
      let abort_fut = Fut.abort fut in
      Oth.Assert.true_ "Fut.state abort_fut = `Undet" (Fut.state abort_fut = `Undet);
      ignore (Fut.run_with_state abort_fut state);
      Oth.Assert.true_ "Fut.state abort_fut = `Undet" (Fut.state abort_fut = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set trigger_next_step ()) state);
      Oth.Assert.true_ "Fut.state abort_fut = `Det ()" (Fut.state abort_fut = `Det ()))

let () =
  Oth.(
    run
      ~file:__FILE__
      ~setup:(fun () -> Ok ())
      ~teardown:(fun _ -> ())
      (fun _ ->
        parallel
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
            test_cancel;
            test_cancel_deep;
            test_abort_determined_after_completed;
          ]))
