module Fut = Abb_fut.Make (struct
  type t = unit
end)

open Fut.Infix_monad
open Fut.Infix_app

exception Foo

let test1 =
  Oth.test ~desc:"Throwing an exception aborts undetermined futures" ~name:"Exception #1" (fun _ ->
      let state = Abb_fut.State.create () in
      let raising = ref false in
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 =
        fut1
        >>| fun v ->
        raising := true;
        raise Foo
      in
      let v = Random.int 10 in
      ignore (Fut.run_with_state (Fut.Promise.set p1 v) state);
      assert !raising;
      assert (Fut.state fut1 = `Det v);
      match Fut.state fut2 with
        | `Exn (Foo, Some _) -> ()
        | _                  -> assert false)

let test2 =
  Oth.test ~desc:"Throwing aborts all connected applicatives" ~name:"Exception #2" (fun _ ->
      let state = Abb_fut.State.create () in
      let raising = ref false in
      let executed_anyways = ref false in
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 =
        fut1
        >>| fun _ ->
        raising := true;
        raise Foo
      in
      let both v1 v2 = (v1, v2) in
      let fut3 = both <$> fut1 <*> fut2 >>| fun (v1, v2) -> executed_anyways := true in
      ignore (Fut.run_with_state fut3 state);
      ignore (Fut.run_with_state (Fut.Promise.set p1 ()) state);
      assert !raising;
      assert (not !executed_anyways);
      assert (Fut.state fut1 = `Det ());
      (match Fut.state fut2 with
        | `Exn (Foo, Some _) -> ()
        | _                  -> assert false);
      match Fut.state fut3 with
        | `Exn (Foo, Some _) -> ()
        | _                  -> assert false)

let test3 =
  Oth.test ~desc:"Await evaluates to `Aborted on exception" ~name:"Exception #3" (fun _ ->
      let state = Abb_fut.State.create () in
      let raising = ref false in
      let executed_anyways = ref false in
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 =
        fut1
        >>| fun _ ->
        raising := true;
        raise Foo
      in
      let both v1 v2 = (v1, v2) in
      let fut3 = both <$> fut1 <*> fut2 >>| fun (v1, v2) -> executed_anyways := true in
      let fut4 = Fut.await fut3 in
      ignore (Fut.run_with_state fut4 state);
      ignore (Fut.run_with_state (Fut.Promise.set p1 ()) state);
      assert !raising;
      assert (not !executed_anyways);
      assert (Fut.state fut1 = `Det ());
      (match Fut.state fut2 with
        | `Exn (Foo, Some _) -> ()
        | _                  -> assert false);
      (match Fut.state fut3 with
        | `Exn (Foo, Some _) -> ()
        | _                  -> assert false);
      match Fut.state fut4 with
        | `Det (`Exn (Foo, Some _)) -> ()
        | _                         -> assert false)

let test4 =
  Oth.test
    ~desc:"Setting a promise to an exception fails the whole chain"
    ~name:"Exception #4"
    (fun _ ->
      let state = Abb_fut.State.create () in
      let raising = ref false in
      let executed_anyways = ref false in
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 =
        fut1
        >>| fun _ ->
        raising := true;
        raise Foo
      in
      let both v1 v2 = (v1, v2) in
      let fut3 = both <$> fut1 <*> fut2 >>| fun (v1, v2) -> executed_anyways := true in
      let fut4 = Fut.await fut3 in
      ignore (Fut.run_with_state fut4 state);
      ignore (Fut.run_with_state (Fut.Promise.set_exn p1 (Foo, None)) state);
      assert (not !raising);
      assert (not !executed_anyways);
      (match Fut.state fut1 with
        | `Exn (Foo, None) -> ()
        | _                -> assert false);
      (match Fut.state fut2 with
        | `Exn (Foo, None) -> ()
        | _                -> assert false);
      (match Fut.state fut3 with
        | `Exn (Foo, None) -> ()
        | _                -> assert false);
      match Fut.state fut4 with
        | `Det (`Exn (Foo, None)) -> ()
        | _                       -> assert false)

let test5 =
  Oth.test ~desc:"Await evaluates to `Aborted on exception" ~name:"Exception #5" (fun _ ->
      let state = Abb_fut.State.create () in
      let raising = ref false in
      let executed_anyways = ref false in
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = Fut.Promise.future p2 in
      let fut3 =
        fut2
        >>| fun _ ->
        raising := true;
        raise Foo
      in
      let both v1 v2 = (v1, v2) in
      let fut4 = both <$> fut1 <*> fut3 >>| fun (v1, v2) -> executed_anyways := true in
      let fut4 = Fut.await fut4 in
      ignore (Fut.run_with_state fut4 state);
      ignore (Fut.run_with_state (Fut.Promise.set p2 ()) state);
      assert !raising;
      assert (not !executed_anyways);
      (match Fut.state fut1 with
        | `Exn (Foo, Some _) -> ()
        | _                  -> assert false);
      assert (Fut.state fut2 = `Det ());
      (match Fut.state fut3 with
        | `Exn (Foo, Some _) -> ()
        | _                  -> assert false);
      match Fut.state fut4 with
        | `Det (`Exn (Foo, Some _)) -> ()
        | _                         -> assert false)

let () =
  Random.self_init ();
  Oth.(run (parallel [ test1; test2; test3; test4; test5 ]))
