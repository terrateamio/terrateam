module Make (Abb : Abb_intf.S) = struct
  module Oth_abb = Oth_abb.Make (Abb)
  module Fut_comb = Abb_future_combinators.Make (Abb.Future)

  let thread_run_test =
    Oth_abb.test ~desc:"Simple increment in thread" ~name:"Thread run" (fun () ->
        let open Abb.Future.Infix_monad in
        let n = Random.int 10 in
        Abb.Thread.run (fun () -> n + 1) >>| fun n' -> assert (n + 1 = n'))

  let double_abort_test =
    Oth_abb.test ~name:"Double abort" (fun () ->
        let open Abb.Future.Infix_monad in
        (* Start two threads that just sleep *)
        Abb.Future.fork (Abb.Thread.run (fun () -> Unix.sleepf 0.5))
        >>= fun fut_1 ->
        Abb.Future.fork (Abb.Thread.run (fun () -> Unix.sleepf 0.5))
        >>= fun fut_2 ->
        (* Wait for them to finish, this way we're guaranteed that both will
           have pending events. *)
        Unix.sleep 1;
        (* Take the first one that is finished and abort the other.  This way we
           know that the other event will be handled. *)
        Fut_comb.first fut_1 fut_2
        >>= fun ((), other) ->
        Abb.Future.abort other
        >>| fun () ->
        assert (Abb.Future.state fut_1 = `Aborted || Abb.Future.state fut_2 = `Aborted))

  let test = Oth_abb.serial [ thread_run_test; double_abort_test ]
end
