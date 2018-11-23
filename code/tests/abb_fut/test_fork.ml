module Fut = Abb_fut
open Fut.Infix_monad
open Fut.Infix_app

let test1 =
  Oth.test
    ~desc:"Testing fork background"
    ~name:"Fork test #1"
    (fun _ ->
       let promise = Fut.Promise.create () in
       let fut1 = Fut.Promise.future promise in
       let fut2 = Fut.fork fut1 in
       ignore (Fut.run_with_state fut2 (Fut.State.create ()));
       assert (Fut.state fut2 = `Det ());
       assert (Fut.state fut1 = `Undet);
       ignore (Fut.run_with_state (Fut.Promise.set promise ()) (Fut.State.create ()));
       assert (Fut.state fut1 = `Det ()))

let test2 =
  Oth.test
    ~desc:"Testing fork background"
    ~name:"Fork test #2"
    (fun _ ->
       let promise = Fut.Promise.create () in
       let fut1 = Fut.Promise.future promise in
       let fut2 =
         Fut.fork fut1
         >>= fun () ->
         fut1
         >>| fun () ->
         ()
       in
       ignore (Fut.run_with_state fut2 (Fut.State.create ()));
       assert (Fut.state fut2 = `Undet);
       assert (Fut.state fut1 = `Undet);
       ignore (Fut.run_with_state (Fut.Promise.set promise ()) (Fut.State.create ()));
       assert (Fut.state fut1 = `Det ());
       assert (Fut.state fut2 = `Det ()))

let () =
  Random.self_init ();
  Oth.(
    run
      (parallel [ test1
                ; test2
                ]))
