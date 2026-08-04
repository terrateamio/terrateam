(* Basic test for undo functionality of revops. *)

let initial = "Initial"
let changed = "Changed"
let state = ref initial

let oprev =
  Revops.Oprev.make
    (fun () ->
      let old = !state in
      state := changed;
      old)
    (fun old -> state := old)

let () =
  Revops.run_in_context oprev (fun threaded ->
      Oth.Assert.true_ "threaded = initial" (threaded = initial);
      Oth.Assert.true_ "!state = changed" (!state = changed))

(* After the run in context, the state should be restored. *)
let () = Oth.Assert.true_ "!state = initial" (!state = initial)
