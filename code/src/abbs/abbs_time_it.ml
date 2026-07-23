(* Some schedulers do not return a fresh clock on every [Abb.Sys.monotonic]
   call: they cache the clock and refresh it only at a particular point in the
   event-loop cycle.  Depending on the scheduler, a continuation that resumes
   inside an I/O completion callback can observe a clock that was last updated
   before the loop blocked, so a [monotonic ()] read taken there is stale by
   the whole blocking duration -- and the elapsed time gets misattributed to
   whatever code happens to run after the clock is next refreshed.

   [Abb.Sys.sleep 0.0] yields to the event loop, forcing the continuation onto
   a later loop iteration where the clock has been refreshed.  We yield before
   *both* reads -- yielding only before [stop] would fix [stop] but leave
   [start] stale, relocating the misattributed time rather than removing it. *)
let run' msg f =
  let open Abb.Future.Infix_monad in
  Abb.Sys.sleep 0.0
  >>= fun () ->
  Abb.Sys.monotonic ()
  >>= fun start ->
  f ()
  >>= fun ret ->
  Abb.Sys.sleep 0.0
  >>= fun () ->
  Abb.Sys.monotonic ()
  >>= fun stop ->
  msg ret (stop -. start);
  Abb.Future.return ret

let run msg f = run' (fun _ -> msg) f
