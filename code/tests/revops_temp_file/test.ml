(* Basic test for temp_file revop. *)

let is_ok = function | Ok _ -> true | Error _ -> false
let is_error = function | Ok _ -> false | Error _ -> true

let filename_oprev = Revops_sys.temp_file ()

let filename = Revops.run_in_context
		 filename_oprev
		 (fun filename ->
		  assert (is_ok (CCResult.guard (fun () -> Unix.access filename [Unix.F_OK])));
                  filename)

let() = assert (is_error (CCResult.guard (fun () -> Unix.access filename [Unix.F_OK])))
