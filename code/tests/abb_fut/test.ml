module Fut = Abb_fut.Make (struct
  type data = unit

  let zero_data = ()

  type t = unit
end)

open Fut.Infix_monad
open Fut.Infix_app

let test1 =
  Oth.test ~desc:"Setting a future executes the watchers" ~name:"Basic #1" (fun _ ->
      let state = Abb_fut.State.create () in
      let r = ref None in
      let p1 = Fut.Promise.create () in
      let _ = Fut.Promise.future p1 >>| fun v -> r := Some v in
      let v = Random.int 10 in
      ignore (Fut.run_with_state (Fut.Promise.set p1 v) state);
      Oth.Assert.true_ "!r = Some v" (!r = Some v))

let test2 =
  Oth.test ~desc:"Setting a future executes a sequence of watchers" ~name:"Basic #2" (fun _ ->
      let state = Abb_fut.State.create () in
      let r = ref 0 in
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let _ =
        fut1 >>= fun v -> Fut.return (v + 1) >>= fun v -> Fut.return (v + 1) >>| fun v -> r := v
      in
      let v = Random.int 10 in
      ignore (Fut.run_with_state (Fut.Promise.set p1 v) state);
      Oth.Assert.true_ "!r = v + 2" (!r = v + 2))

let test3 =
  Oth.test ~desc:"Sequential evaluation of a both function" ~name:"Both" (fun _ ->
      let state = Abb_fut.State.create () in
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = Fut.Promise.future p2 in
      let both f1 f2 = f1 >>= fun v1 -> f2 >>= fun v2 -> Fut.return (v1, v2) in
      let fut3 =
        both fut1 fut2
        >>| fun (v1, v2) ->
        Oth.Assert.Eq.int ~expected:1 ~actual:v1;
        Oth.Assert.Eq.int ~expected:2 ~actual:v2
      in
      ignore (Fut.run_with_state (Fut.Promise.set p1 1) state);
      ignore (Fut.run_with_state (Fut.Promise.set p2 2) state);
      Oth.Assert.true_ "Fut.state fut3 = `Det ()" (Fut.state fut3 = `Det ()))

let test4 =
  Oth.test ~desc:"Await is the determined value" ~name:"Await" (fun _ ->
      let state = Abb_fut.State.create () in
      let p1 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = Fut.await fut1 >>| fun v -> Oth.Assert.true_ "v = `Det ()" (v = `Det ()) in
      ignore (Fut.run_with_state (Fut.Promise.set p1 ()) state);
      Oth.Assert.true_ "Fut.state fut2 = `Det ()" (Fut.state fut2 = `Det ()))

let test5 =
  Oth.test ~desc:"An applicative implementation of both" ~name:"Both Applicative" (fun _ ->
      let state = Abb_fut.State.create () in
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = Fut.Promise.future p2 in
      let both v1 v2 = (v1, v2) in
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
      ignore (Fut.run_with_state (Fut.Promise.set p2 2) state);
      let state = Fut.state fut3 in
      Oth.Assert.true_ "state = `Det ()" (state = `Det ()))

let test6 =
  Oth.test
    ~desc:"Ensure the order of the applicative execution"
    ~name:"Applicative Order Test #1"
    (fun _ ->
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
      ignore (Fut.run_with_state (Fut.Promise.set p2 2) state);
      Oth.Assert.Eq.int ~expected:2 ~actual:!r;
      let state = Fut.state fut3 in
      Oth.Assert.true_ "state = `Det ()" (state = `Det ()))

let test7 =
  Oth.test
    ~desc:"Ensure the order of the applicative execution"
    ~name:"Applicative Order Test #2"
    (fun _ ->
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
      ignore (Fut.run_with_state (Fut.Promise.set p2 2) state);
      Oth.Assert.Eq.int ~expected:0 ~actual:!r;
      ignore (Fut.run_with_state (Fut.Promise.set p1 1) state);
      Oth.Assert.Eq.int ~expected:2 ~actual:!r;
      let state = Fut.state fut3 in
      Oth.Assert.true_ "state = `Det ()" (state = `Det ()))

let test8 =
  Oth.test ~desc:"Sequential evaluation of a both function, in reverse order" ~name:"Both" (fun _ ->
      let state = Abb_fut.State.create () in
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let fut1 = Fut.Promise.future p1 in
      let fut2 = Fut.Promise.future p2 in
      let both f1 f2 = f1 >>= fun v1 -> f2 >>= fun v2 -> Fut.return (v1, v2) in
      let fut3 =
        both fut1 fut2
        >>| fun (v1, v2) ->
        Oth.Assert.Eq.int ~expected:1 ~actual:v1;
        Oth.Assert.Eq.int ~expected:2 ~actual:v2
      in
      ignore (Fut.run_with_state (Fut.Promise.set p2 2) state);
      ignore (Fut.run_with_state (Fut.Promise.set p1 1) state);
      Oth.Assert.true_ "Fut.state fut3 = `Det ()" (Fut.state fut3 = `Det ()))

let test9 =
  Oth.test
    ~desc:"Ensure the outer fut of combined futures is determined with map"
    ~name:"Nested Fut"
    (fun _ ->
      let state = Abb_fut.State.create () in
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let fut = Fut.Promise.future p1 >>= fun v1 -> Fut.Promise.future p2 >>| fun v2 -> (v1, v2) in
      ignore (Fut.run_with_state (Fut.Promise.set p1 1) state);
      ignore (Fut.run_with_state (Fut.Promise.set p2 2) state);
      Oth.Assert.true_ "Fut.state fut = `Det (1, 2)" (Fut.state fut = `Det (1, 2)))

let () =
  Random.self_init ();
  Oth.(
    run
      ~file:__FILE__
      ~setup:(fun () -> Ok ())
      ~teardown:(fun _ -> ())
      (fun _ -> parallel [ test1; test2; test3; test4; test5; test6; test7; test8; test9 ]))
