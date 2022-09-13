module Fut = Abb_fut.Make (struct
  type t = unit
end)

module Fut_comb = Abb_future_combinators.Make (Fut)

let dummy_state = Abb_fut.State.create ()

let test_success =
  Oth.test ~name:"App success" (fun _ ->
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let both =
        Fut_comb.Infix_result_app.(
          (fun a b -> (a, b)) <$> Fut.Promise.future p1 <*> Fut.Promise.future p2)
      in
      ignore (Fut.run_with_state both dummy_state);
      assert (Fut.state both = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set p1 (Ok 1)) dummy_state);
      assert (Fut.state both = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set p2 (Ok 2)) dummy_state);
      assert (Fut.state both = `Det (Ok (1, 2))))

let test_first_error =
  Oth.test ~name:"First fail" (fun _ ->
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let both =
        Fut_comb.Infix_result_app.(
          (fun a b -> (a, b)) <$> Fut.Promise.future p1 <*> Fut.Promise.future p2)
      in
      ignore (Fut.run_with_state both dummy_state);
      assert (Fut.state both = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set p1 (Error 1)) dummy_state);
      assert (Fut.state both = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set p2 (Ok 2)) dummy_state);
      assert (Fut.state both = `Det (Error 1)))

let test_second_error =
  Oth.test ~name:"Second fail" (fun _ ->
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let both =
        Fut_comb.Infix_result_app.(
          (fun a b -> (a, b)) <$> Fut.Promise.future p1 <*> Fut.Promise.future p2)
      in
      ignore (Fut.run_with_state both dummy_state);
      assert (Fut.state both = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set p1 (Ok 1)) dummy_state);
      assert (Fut.state both = `Undet);
      ignore (Fut.run_with_state (Fut.Promise.set p2 (Error 2)) dummy_state);
      assert (Fut.state both = `Det (Error 2)))

let test_first_abort =
  Oth.test ~name:"First Abort" (fun _ ->
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let both =
        Fut_comb.Infix_result_app.(
          (fun a b -> (a, b)) <$> Fut.Promise.future p1 <*> Fut.Promise.future p2)
      in
      ignore (Fut.run_with_state both dummy_state);
      assert (Fut.state both = `Undet);
      ignore (Fut.run_with_state (Fut.abort (Fut.Promise.future p1)) dummy_state);
      assert (Fut.state both = `Aborted);
      assert (Fut.state (Fut.Promise.future p2) = `Aborted))

let test_second_abort =
  Oth.test ~name:"Second Abort" (fun _ ->
      let p1 = Fut.Promise.create () in
      let p2 = Fut.Promise.create () in
      let both =
        Fut_comb.Infix_result_app.(
          (fun a b -> (a, b)) <$> Fut.Promise.future p1 <*> Fut.Promise.future p2)
      in
      ignore (Fut.run_with_state both dummy_state);
      assert (Fut.state both = `Undet);
      ignore (Fut.run_with_state (Fut.abort (Fut.Promise.future p2)) dummy_state);
      assert (Fut.state both = `Aborted);
      assert (Fut.state (Fut.Promise.future p1) = `Aborted))

let () =
  Oth.(
    run
      (parallel
         [ test_success; test_first_error; test_second_error; test_first_abort; test_second_abort ]))
