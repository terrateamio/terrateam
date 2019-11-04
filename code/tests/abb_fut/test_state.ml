module Fut = Abb_fut.Make (struct
  type t = int
end)

open Fut.Infix_monad
open Fut.Infix_app

let test1 =
  Oth.test ~desc:"State update" ~name:"State test #1" (fun _ ->
      let state = Abb_fut.State.create 0 in
      let fut =
        Fut.with_state (fun s ->
            (Abb_fut.State.set_state (Abb_fut.State.state s + 1) s, Fut.return ()))
      in
      let state = Fut.run_with_state fut state in
      assert (Fut.state fut = `Det ());
      assert (Abb_fut.State.state state = 1))

let test2 =
  Oth.test ~desc:"State update" ~name:"State test #2" (fun _ ->
      let state = Abb_fut.State.create 0 in
      let promise = Fut.Promise.create () in
      let fut1 = Fut.Promise.future promise in
      let fut2 =
        fut1
        >>= fun () ->
        Fut.with_state (fun s ->
            (Abb_fut.State.set_state (Abb_fut.State.state s + 1) s, Fut.return ()))
      in
      let state = Fut.run_with_state (Fut.Promise.set promise ()) state in
      assert (Fut.state fut2 = `Det ());
      assert (Abb_fut.State.state state = 1))

let test3 =
  Oth.test ~desc:"State update" ~name:"State test #3" (fun _ ->
      let state = Abb_fut.State.create 0 in
      let fut =
        Fut.with_state (fun s ->
            (Abb_fut.State.set_state (Abb_fut.State.state s + 1) s, Fut.return ()))
        >>| fun () -> 10
      in
      let state = Fut.run_with_state fut state in
      assert (Fut.state fut = `Det 10);
      assert (Abb_fut.State.state state = 1))

let () =
  Random.self_init ();
  Oth.(run (parallel [ test1; test2; test3 ]))
