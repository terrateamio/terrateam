module Fut = Abb_fut
open Fut.Infix_monad
open Fut.Infix_app

let dummy_state = Fut.State.create ()

let test1 =
  Oth.test
    ~desc:"Setting a future executes the watchers"
    ~name:"Basic #1"
    (fun _ ->
      let r = ref None in
      let p1 = Fut.Promise.create () in
      let _ =
        Fut.Promise.future p1
        >>| fun v -> r := Some v
      in
      let v = Random.int 10 in
      ignore (Fut.run_with_state (Fut.Promise.set p1 v) dummy_state);
      assert (!r = Some v))

let test2 =
  Oth.test
    ~desc:"Setting a future executes a sequence of watchers"
    ~name:"Basic #2"
    (fun _ ->
      let r = ref 0 in
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let _ =
        fut1
        >>= fun v ->
        Fut.return (v + 1)
        >>= fun v ->
        Fut.return (v + 1)
        >>| fun v ->
        r := v
      in
      let v = Random.int 10 in
      ignore (Fut.run_with_state (Fut.Promise.set p1 v) dummy_state);
      assert (!r = (v + 2)))

let test3 =
  Oth.test
    ~desc:"Sequential evaluation of a both function"
    ~name:"Both"
    (fun _ ->
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = Fut.Promise.future p2 in
      let both f1 f2 =
        f1
        >>= fun v1 ->
        f2
        >>= fun v2 ->
        Fut.return (v1, v2)
      in
      let fut3 =
        both fut1 fut2
        >>| fun (v1, v2) ->
        assert (v1 = 1);
        assert (v2 = 2)
      in
      ignore (Fut.run_with_state (Fut.Promise.set p1 1) dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set p2 2) dummy_state);
      assert (Fut.state fut3 = `Det ()))

let test4 =
  Oth.test
    ~desc:"Await is the determined value"
    ~name:"Await"
    (fun _ ->
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 =
        Fut.await fut1
        >>| fun v ->
        assert (v = `Det ())
      in
      ignore (Fut.run_with_state (Fut.Promise.set p1 ()) dummy_state);
      assert (Fut.state fut2 = `Det ()))

let test5 =
  Oth.test
    ~desc:"An applicative implementation of both"
    ~name:"Both Applicative"
    (fun _ ->
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = Fut.Promise.future p2 in
      let both v1 v2 = (v1, v2) in
      let fut3 =
        both <$> fut1 <*> fut2
        >>| fun (v1, v2) ->
        assert (v1 = 1);
        assert (v2 = 2)
      in
      ignore (Fut.run_with_state (Fut.Promise.set p1 1) dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set p2 2) dummy_state);
      let state = Fut.state fut3 in
      assert (state = `Det ()))

let test6 =
  Oth.test
    ~desc:"Ensure the order of the applicative execution"
    ~name:"Applicative Order Test #1"
    (fun _ ->
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
        both <$> fut1 <*> fut2
        >>| fun (v1, v2) ->
        assert (v1 = 1);
        assert (v2 = 2)
      in
      ignore (Fut.run_with_state (Fut.Promise.set p1 1) dummy_state);
      assert (!r = 1);
      ignore (Fut.run_with_state (Fut.Promise.set p2 2) dummy_state);
      assert (!r = 2);
      let state = Fut.state fut3 in
      assert (state = `Det ()))

let test7 =
  Oth.test
    ~desc:"Ensure the order of the applicative execution"
    ~name:"Applicative Order Test #2"
    (fun _ ->
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
        both <$> fut1 <*> fut2
        >>| fun (v1, v2) ->
        assert (v1 = 1);
        assert (v2 = 2)
      in
      ignore (Fut.run_with_state (Fut.Promise.set p2 2) dummy_state);
      assert (!r = 0);
      ignore (Fut.run_with_state (Fut.Promise.set p1 1) dummy_state);
      assert (!r = 2);
      let state = Fut.state fut3 in
      assert (state = `Det ()))

let test8 =
  Oth.test
    ~desc:"Sequential evaluation of a both function, in reverse order"
    ~name:"Both"
    (fun _ ->
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = Fut.Promise.future p2 in
      let both f1 f2 =
        f1
        >>= fun v1 ->
        f2
        >>= fun v2 ->
        Fut.return (v1, v2)
      in
      let fut3 =
        both fut1 fut2
        >>| fun (v1, v2) ->
        assert (v1 = 1);
        assert (v2 = 2)
      in
      ignore (Fut.run_with_state (Fut.Promise.set p2 2) dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set p1 1) dummy_state);
      assert (Fut.state fut3 = `Det ()))

let test9 =
  Oth.test
    ~desc:"Ensure the outer fut of combined futures is determined with map"
    ~name:"Nested Fut"
    (fun _ ->
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let fut =
        Fut.Promise.future p1
        >>= fun v1 ->
        Fut.Promise.future p2
        >>| fun v2 ->
        (v1, v2)
      in
      ignore (Fut.run_with_state (Fut.Promise.set p1 1) dummy_state);
      ignore (Fut.run_with_state (Fut.Promise.set p2 2) dummy_state);
      assert (Fut.state fut = `Det (1, 2)))

let test10 =
  Oth.test
    ~desc:"Foo"
    ~name:"Bar"
    (fun _ ->
       let fut1 = Fut.return () in
       let fut2 = fut1 >>| fun () -> () in
       ignore (Fut.run_with_state fut1 dummy_state);
       ignore (Fut.run_with_state fut2 dummy_state);
       assert (Fut.state fut1 = `Det ());
       assert (Fut.state fut2 = `Det ()))

let () =
  Random.self_init ();
  Oth.(
    run
      (parallel [ test1
                ; test2
                ; test3
                ; test4
                ; test5
                ; test6
                ; test7
                ; test8
                ; test9
                ; test10
                ]))

