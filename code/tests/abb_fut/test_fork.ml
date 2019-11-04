module Fut = Abb_fut.Make (struct
  type t = unit
end)

open Fut.Infix_monad
open Fut.Infix_app

let test1 =
  Oth.test ~desc:"Testing fork background" ~name:"Fork test #1" (fun _ ->
      let state = Abb_fut.State.create () in
      let promise = Fut.Promise.create () in
      let fut1 = Fut.Promise.future promise in
      let fut2 = Fut.fork fut1 in
      ignore (Fut.run_with_state fut2 state);
      assert (Fut.state fut1 = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set promise ()) state);
      assert (Fut.state fut1 = `Det ());
      match Fut.state fut2 with
        | `Det t -> assert (Fut.state t = `Det ())
        | _      -> assert false)

let test2 =
  Oth.test ~desc:"Testing fork background" ~name:"Fork test #2" (fun _ ->
      let state = Abb_fut.State.create () in
      let promise = Fut.Promise.create () in
      let fut1 = Fut.Promise.future promise in
      let fut2 = Fut.fork fut1 in
      ignore (Fut.run_with_state fut2 state);
      assert (Fut.state fut1 = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set promise ()) state);
      assert (Fut.state fut1 = `Det ());
      match Fut.state fut2 with
        | `Det t -> assert (Fut.state t = `Det ())
        | _      -> assert false)

let test3 =
  Oth.test ~desc:"Testing aborting a fork" ~name:"Fork abort" (fun _ ->
      let state = Abb_fut.State.create () in
      let promise = Fut.Promise.create () in
      let fut1 = Fut.Promise.future promise in
      let fut2 = Fut.fork fut1 >>= fun fut -> fut >>| fun () -> () in
      ignore (Fut.run_with_state fut2 state);
      assert (Fut.state fut2 = `Undet);
      assert (Fut.state fut1 = `Undet);
      ignore (Fut.run_with_state (Fut.abort fut2) state);
      assert (Fut.state fut1 = `Aborted);
      assert (Fut.state fut2 = `Aborted))

let () =
  Random.self_init ();
  Oth.(run (parallel [ test1; test2; test3 ]))
