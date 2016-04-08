(* Basic test for temp_file revop. *)

open Core.Std

let filename_oprev = Revops_sys.temp_file ()

let filename = Revops.run_in_context
		 filename_oprev
		 (fun filename ->
		  assert (Result.is_ok (Unix.access filename [`Exists]));
                  filename)

let() = assert (Result.is_error (Unix.access filename [`Exists]))
