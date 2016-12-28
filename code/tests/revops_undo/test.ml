(* Basic test for undo functionality of revops. *)

let initial = "Initial"

let changed = "Changed"

let state = ref initial

let oprev = Revops.Oprev.make
              (fun () ->
               let old = !state in
               state := changed;
               old)
              (fun old -> state := old)

let () = Revops.run_in_context
           oprev
           (fun threaded ->
            assert (threaded = initial);
            assert (!state = changed))

(* After the run in context, the state should be restored. *)
let () = assert (!state = initial)
