module Fut = Abb_fut.Make (struct
  type data = unit

  let zero_data = ()

  type t = unit
end)

open Fut.Infix_monad

let test1 =
  Oth.test ~desc:"Testing fork background" ~name:"Fork test #1" (fun _ ->
      let state = Abb_fut.State.create () in
      let promise = Fut.Promise.create () in
      let fut1 = Fut.Promise.future promise in
      let fut2 = Fut.fork fut1 in
      ignore (Fut.run_with_state fut2 state);
      Oth.Assert.true_ "Fut.state fut1 = `Undet" (Fut.state fut1 = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set promise ()) state);
      Oth.Assert.true_ "Fut.state fut1 = `Det ()" (Fut.state fut1 = `Det ());
      match Fut.state fut2 with
      | `Det t -> Oth.Assert.true_ "Fut.state t = `Det ()" (Fut.state t = `Det ())
      | _ -> Oth.Assert.false_ "Fork test #1: unexpected value")

let test2 =
  Oth.test ~desc:"Testing fork background" ~name:"Fork test #2" (fun _ ->
      let state = Abb_fut.State.create () in
      let promise = Fut.Promise.create () in
      let fut1 = Fut.Promise.future promise in
      let fut2 = Fut.fork fut1 in
      ignore (Fut.run_with_state fut2 state);
      Oth.Assert.true_ "Fut.state fut1 = `Undet" (Fut.state fut1 = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set promise ()) state);
      Oth.Assert.true_ "Fut.state fut1 = `Det ()" (Fut.state fut1 = `Det ());
      match Fut.state fut2 with
      | `Det t -> Oth.Assert.true_ "Fut.state t = `Det ()" (Fut.state t = `Det ())
      | _ -> Oth.Assert.false_ "Fork test #2: unexpected value")

let test3 =
  Oth.test ~desc:"Testing aborting a fork" ~name:"Fork abort" (fun _ ->
      let state = Abb_fut.State.create () in
      let promise = Fut.Promise.create () in
      let fut1 = Fut.Promise.future promise in
      let fut2 = Fut.fork fut1 >>= fun fut -> fut >>| fun () -> () in
      ignore (Fut.run_with_state fut2 state);
      Oth.Assert.true_ "Fut.state fut2 = `Undet" (Fut.state fut2 = `Undet);
      Oth.Assert.true_ "Fut.state fut1 = `Undet" (Fut.state fut1 = `Undet);
      ignore (Fut.run_with_state (Fut.abort fut2) state);
      Oth.Assert.true_ "Fut.state fut1 = `Aborted" (Fut.state fut1 = `Aborted);
      Oth.Assert.true_ "Fut.state fut2 = `Aborted" (Fut.state fut2 = `Aborted))

let () =
  Random.self_init ();
  Oth.(
    run
      ~file:__FILE__
      ~setup:(fun () -> Ok ())
      ~teardown:(fun _ -> ())
      (fun _ -> parallel [ test1; test2; test3 ]))
