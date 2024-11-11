module Make (Abb : Abb_intf.S) = struct
  module Oth_abb = Oth_abb.Make (Abb)
  module Fut_comb = Abb_future_combinators.Make (Abb.Future)

  let basic_test =
    Oth_abb.test ~desc:"A few sleeps" ~name:"Sleep test" (fun () ->
        let open Abb.Future.Infix_monad in
        Abb.Sys.sleep 1.0 >>= fun () -> Abb.Sys.sleep 2.0 >>= fun () -> Abb.Future.return ())

  let precision_test =
    Oth_abb.test
      ~desc:"A lot of concurrent sleep to test latency"
      ~name:"Overloaded sleep precision test"
      (fun () ->
        let open Abb.Future.Infix_monad in
        let open Abb.Future.Infix_app in
        let max_inprecision = ref 0.0 in
        let min_inprecision = ref 0.0 in
        let count = ref 0 in
        let total = ref 0.0 in
        let update_stats scheduled_time duration () =
          Abb.Sys.time ()
          >>| fun curr_time ->
          let diff = curr_time -. scheduled_time -. duration in
          max_inprecision := max !max_inprecision diff;
          min_inprecision := min !min_inprecision diff;
          count := !count + 1;
          total := !total +. diff
        in
        let rec timer_loop = function
          | 0 -> []
          | n ->
              let duration = Random.float 1.0 in
              let fut =
                Abb.Sys.time ()
                >>= fun scheduled_time ->
                Abb.Sys.sleep duration >>= fun () -> update_stats scheduled_time duration ()
              in
              fut :: timer_loop (n - 1)
        in
        let futures = timer_loop 5000 in
        Fut_comb.all futures
        >>| fun _ ->
        Printf.printf
          "Max: %f Min: %f Count: %d Avg: %f\n%!"
          !max_inprecision
          !min_inprecision
          !count
          (!total /. float !count);
        assert (!max_inprecision <= 0.5))

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
        assert (end_time -. start_time <= 1.1);
        assert (ret = `Timedout);
        (* Ensure that the future eventually does complete *)
        fut >>| fun v -> assert (v = `Ok))

  let test = Oth_abb.serial [ basic_test; (* precision_test; *) timeout_test ]
end
