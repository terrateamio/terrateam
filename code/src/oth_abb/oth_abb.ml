module Make (Abb : Abb_intf.S ) = struct
  module Fut_comb = Abb_future_combinators.Make(Abb.Future)

  module Test = struct
    type t = (Oth.State.t -> Oth.Run_result.t Abb.Future.t)
  end

  let time_test f =
    let open Abb.Future.Infix_monad in
    let start = Unix.gettimeofday () in
    try
      Abb.Future.await (f ())
      >>= fun res ->
      let stop = Unix.gettimeofday () in
      let duration = Duration.of_f (stop -. start) in
      match res with
        | `Det res ->
          Abb.Future.return (duration, `Ok)
        | `Aborted ->
          assert false
        | `Exn _ as err ->
          Abb.Future.return (duration, err)
    with
      | exn ->
        let stop = Unix.gettimeofday () in
        let duration = Duration.of_f (stop -. start) in
        Abb.Future.return (duration, `Exn (exn, Some (Printexc.get_raw_backtrace ())))

  let serial : Test.t list -> Test.t = fun tests state ->
    let open Abb.Future.Infix_monad in
    Fut_comb.List.map ~f:(fun test -> test state) tests
    >>= fun deep_result ->
    let flat_rr = CCListLabels.flat_map ~f:Oth.Run_result.test_results deep_result in
    Abb.Future.return (Oth.Run_result.of_test_results flat_rr)

  let parallel = serial

  let timeout duration test = failwith "nyi"

  let test ?desc ~name f state =
    let open Abb.Future.Infix_monad in
    time_test f
    >>= fun (duration, res) ->
    let test_results = Oth.Test_result.([{ name; desc; duration; res }]) in
    Abb.Future.return (Oth.Run_result.of_test_results test_results)

  let result_test f s = failwith "nyi"

  let to_sync_test test =
    Oth.raw_test
      (fun state ->
         let sched = Abb.Scheduler.create () in
         let res =
           Abb.Scheduler.run
             sched
             (fun () -> test state)
         in
         match res with
           | `Det rr -> rr
           | _ -> assert false)
end
