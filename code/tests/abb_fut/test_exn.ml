module Fut = Abb_fut.Make (struct
  type data = unit

  let zero_data = ()

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
        >>| fun _ ->
        raising := true;
        raise Foo
      in
      let v = Random.int 10 in
      ignore (Fut.run_with_state (Fut.Promise.set p1 v) state);
      Oth.Assert.true_ "!raising" !raising;
      Oth.Assert.true_ "Fut.state fut1 = `Det v" (Fut.state fut1 = `Det v);
      match Fut.state fut2 with
      | `Exn (Foo, Some _) -> ()
      | _ -> Oth.Assert.false_ "Exception #1: unexpected value")

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
      let fut3 = both <$> fut1 <*> fut2 >>| fun (_v1, _v2) -> executed_anyways := true in
      ignore (Fut.run_with_state fut3 state);
      ignore (Fut.run_with_state (Fut.Promise.set p1 ()) state);
      Oth.Assert.true_ "!raising" !raising;
      Oth.Assert.true_ "not !executed_anyways" (not !executed_anyways);
      Oth.Assert.true_ "Fut.state fut1 = `Det ()" (Fut.state fut1 = `Det ());
      (match Fut.state fut2 with
      | `Exn (Foo, Some _) -> ()
      | _ -> Oth.Assert.false_ "Exception #2: unexpected value");
      match Fut.state fut3 with
      | `Exn (Foo, Some _) -> ()
      | _ -> Oth.Assert.false_ "Exception #2: unexpected value")

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
      let fut3 = both <$> fut1 <*> fut2 >>| fun (_v1, _v2) -> executed_anyways := true in
      let fut4 = Fut.await fut3 in
      ignore (Fut.run_with_state fut4 state);
      ignore (Fut.run_with_state (Fut.Promise.set p1 ()) state);
      Oth.Assert.true_ "!raising" !raising;
      Oth.Assert.true_ "not !executed_anyways" (not !executed_anyways);
      Oth.Assert.true_ "Fut.state fut1 = `Det ()" (Fut.state fut1 = `Det ());
      (match Fut.state fut2 with
      | `Exn (Foo, Some _) -> ()
      | _ -> Oth.Assert.false_ "Exception #3: unexpected value");
      (match Fut.state fut3 with
      | `Exn (Foo, Some _) -> ()
      | _ -> Oth.Assert.false_ "Exception #3: unexpected value");
      match Fut.state fut4 with
      | `Det (`Exn (Foo, Some _)) -> ()
      | _ -> Oth.Assert.false_ "Exception #3: unexpected value")

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
      let fut3 = both <$> fut1 <*> fut2 >>| fun (_v1, _v2) -> executed_anyways := true in
      let fut4 = Fut.await fut3 in
      ignore (Fut.run_with_state fut4 state);
      ignore (Fut.run_with_state (Fut.Promise.set_exn p1 (Foo, None)) state);
      Oth.Assert.true_ "not !raising" (not !raising);
      Oth.Assert.true_ "not !executed_anyways" (not !executed_anyways);
      (match Fut.state fut1 with
      | `Exn (Foo, None) -> ()
      | _ -> Oth.Assert.false_ "Exception #4: unexpected value");
      (match Fut.state fut2 with
      | `Exn (Foo, None) -> ()
      | _ -> Oth.Assert.false_ "Exception #4: unexpected value");
      (match Fut.state fut3 with
      | `Exn (Foo, None) -> ()
      | _ -> Oth.Assert.false_ "Exception #4: unexpected value");
      match Fut.state fut4 with
      | `Det (`Exn (Foo, None)) -> ()
      | _ -> Oth.Assert.false_ "Exception #4: unexpected value")

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
      let fut4 = both <$> fut1 <*> fut3 >>| fun (_v1, _v2) -> executed_anyways := true in
      let fut4 = Fut.await fut4 in
      ignore (Fut.run_with_state fut4 state);
      ignore (Fut.run_with_state (Fut.Promise.set p2 ()) state);
      Oth.Assert.true_ "!raising" !raising;
      Oth.Assert.true_ "not !executed_anyways" (not !executed_anyways);
      (match Fut.state fut1 with
      | `Exn (Foo, Some _) -> ()
      | _ -> Oth.Assert.false_ "Exception #5: unexpected value");
      Oth.Assert.true_ "Fut.state fut2 = `Det ()" (Fut.state fut2 = `Det ());
      (match Fut.state fut3 with
      | `Exn (Foo, Some _) -> ()
      | _ -> Oth.Assert.false_ "Exception #5: unexpected value");
      match Fut.state fut4 with
      | `Det (`Exn (Foo, Some _)) -> ()
      | _ -> Oth.Assert.false_ "Exception #5: unexpected value")

let test_exn_determined_after_completed =
  Oth.test ~name:"Exn determined after completed" (fun _ ->
      let state = Abb_fut.State.create () in
      let trigger_next_step = Fut.Promise.create () in
      let abort () = Fut.Promise.future trigger_next_step in
      let p = Fut.Promise.create ~abort () in
      let fut = Fut.Promise.future p in
      let exn_fut = Fut.Promise.set_exn p (Failure "foo", None) in
      Oth.Assert.true_ "Fut.state exn_fut = `Undet" (Fut.state exn_fut = `Undet);
      ignore (Fut.run_with_state exn_fut state);
      Oth.Assert.true_ "Fut.state exn_fut = `Undet" (Fut.state exn_fut = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set trigger_next_step ()) state);
      Oth.Assert.true_ "Fut.state exn_fut = `Det ()" (Fut.state exn_fut = `Det ());
      match Fut.state fut with
      | `Undet -> Oth.Assert.false_ "Exn determined after completed: unexpected value"
      | `Det _ -> Oth.Assert.false_ "Exn determined after completed: unexpected value"
      | `Aborted -> Oth.Assert.false_ "Exn determined after completed: unexpected value"
      | `Exn _ -> ())

let test_exn_applicative_determined_after_abort_fun =
  Oth.test ~name:"Exn applicative determined after abort fun" (fun _ ->
      let state = Abb_fut.State.create () in
      let start = Fut.Promise.create () in
      let trigger_next_step = Fut.Promise.create () in
      let abort () = Fut.Promise.future trigger_next_step in
      let fut =
        Fut.Infix_app.(
          (fun _ _ -> ())
          <$> (let open Fut.Infix_monad in
               Fut.Promise.future start >>= fun () -> failwith "exn")
          <*> Fut.Promise.(future (create ~abort ())))
      in
      ignore (Fut.run_with_state fut state);
      Oth.Assert.true_ "Fut.state fut = `Undet" (Fut.state fut = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set start ()) state);
      Oth.Assert.true_ "Fut.state fut = `Undet" (Fut.state fut = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set trigger_next_step ()) state);
      match Fut.state fut with
      | `Undet -> Oth.Assert.false_ "Exn applicative determined after abort fun: unexpected value"
      | `Det _ -> Oth.Assert.false_ "Exn applicative determined after abort fun: unexpected value"
      | `Aborted -> Oth.Assert.false_ "Exn applicative determined after abort fun: unexpected value"
      | `Exn _ -> ())

let () =
  Random.self_init ();
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
            test_exn_determined_after_completed;
            test_exn_applicative_determined_after_abort_fun;
          ]))
