(* Basic test that compose respects undoes in reverse order. *)

open Core.Std

let state = ref []

let push_oprev n = Revops.Oprev.make
		     (fun () -> state := n::!state)
		     (fun () ->
		      assert (List.hd_exn !state = n);
		      state := List.tl_exn !state)

let () = Revops.run_in_context
	   Revops.(push_oprev 1
		   +* push_oprev 2)
	   (fun _ -> assert (!state = [2; 1]))
