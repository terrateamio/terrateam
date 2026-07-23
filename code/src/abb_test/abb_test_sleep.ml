module Make (Abb : Abb_intf.S) = struct
  module Oth_abb = Oth_abb.Make (Abb)
  module Fut_comb = Abb_future_combinators.Make (Abb.Future)

  let basic_test =
    Oth_abb.test ~desc:"A few sleeps" ~name:"Sleep test" (fun () ->
        let open Abb.Future.Infix_monad in
        Abb.Sys.sleep 1.0 >>= fun () -> Abb.Sys.sleep 2.0 >>= fun () -> Abb.Future.return ())

  let timeout_test =
    Oth_abb.test ~desc:"Timeout test" ~name:"Timeout test" (fun () ->
        let open Abb.Future.Infix_monad in
        Abb.Sys.time ()
        >>= fun start_time ->
        let sleep1 = Abb.Sys.sleep 1.0 >>| fun () -> `Timedout in
        let sleep2 = Abb.Sys.sleep 2.0 >>| fun () -> `Ok in
        Fut_comb.first sleep1 sleep2
        >>= fun (ret, fut) ->
        Abb.Sys.time ()
        >>= fun end_time ->
        Oth.Assert.true_ "timeout fired within 1.5s" (end_time -. start_time <= 1.5);
        Oth.Assert.true_ "the faster sleep won the race" (ret = `Timedout);
        (* Ensure that the future eventually does complete *)
        fut >>| fun v -> Oth.Assert.true_ "the slower sleep eventually completed" (v = `Ok))

  let test = Oth_abb.serial [ basic_test; timeout_test ]
end
