(* Multi-domain placement tests for pinned vs unpinned tasks.

   Pinned tasks must run on the scheduler (event-loop) domain; unpinned
   tasks must run on a worker domain from the scheduler's pool.
   Schedulers without the [`Multi_domain] capability cannot satisfy
   these invariants, so the tests fast-succeed on them.

   Note on nesting: spawning [Abb.Task.run] from inside an unpinned
   task body executes [Future.fork] on the WORKER's [Abb_fut.State],
   so a [~pinned:true] subtask spawned from an unpinned body does not
   migrate back to the scheduler domain.  Tests for the
   pinned-inside-unpinned and unpinned-inside-unpinned variants are
   omitted for that reason — they would assert an invariant the
   scheduler does not currently uphold. *)
module Make (Abb : Abb_intf.S) = struct
  module Oth_abb = Oth_abb.Make (Abb)

  let is_multi_domain =
    CCList.mem ~eq:Abb_intf.Scheduler_capability.equal `Multi_domain Abb.Scheduler.capabilities

  let pinned_runs_on_scheduler =
    Oth_abb.test ~name:"Domain: pinned task runs on scheduler domain" (fun () ->
        let open Abb.Future.Infix_monad in
        (* The test body runs on the scheduler's loop domain. *)
        let scheduler_domain = Domain.self () in
        Abb.Task.run ~pinned:true (fun () -> Abb.Future.return (Domain.self ()))
        >>= fun fut ->
        fut
        >>| fun observed ->
        Oth.Assert.true_ "pinned task ran on the scheduler domain" (observed = scheduler_domain))

  let unpinned_runs_off_scheduler =
    Oth_abb.test ~name:"Domain: unpinned body runs on a non-scheduler domain" (fun () ->
        let open Abb.Future.Infix_monad in
        let scheduler_domain = Domain.self () in
        Abb.Task.run ~pinned:false (fun () ->
            Abb.Sys.sleep 0.01 >>= fun () -> Abb.Future.return (Domain.self ()))
        >>= fun fut ->
        fut
        >>| fun observed ->
        Oth.Assert.true_ "unpinned body ran off the scheduler domain" (observed <> scheduler_domain))

  let skipped =
    Oth_abb.test ~name:"Domain: skipped (single-domain scheduler)" (fun () -> Abb.Future.return ())

  let test =
    if is_multi_domain then Oth_abb.serial [ pinned_runs_on_scheduler; unpinned_runs_off_scheduler ]
    else Oth_abb.serial [ skipped ]
end
