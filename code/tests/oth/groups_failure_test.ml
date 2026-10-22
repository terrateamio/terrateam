(* The failure paths of [Oth.run_groups]: a group whose setup fails, beside groups that succeed, and
   an [?after] group whose setup fails.  [groups_test.ml] covers the success path.

   The run itself is [groups_failure_helper.exe], given as the first argument.  [run_groups] prints
   the failure and exits the process, so a check of the exit code cannot be made inside the run.

   Checks go through [check] rather than [assert], for the reason groups_test.ml gives. *)

let check msg b = if not b then failwith ("check failed: " ^ msg)

let holds ~out needle =
  check (Printf.sprintf "output must hold %S" needle) (CCString.mem ~sub:needle out)

let absent ~out needle =
  check (Printf.sprintf "output must not hold %S" needle) (not (CCString.mem ~sub:needle out))

(* [OTH_TAGS] and [OTH_EXCLUDE_TAGS] are emptied, which counts as unset, so a narrowed parent run
   cannot filter the helper's one test away.  [OTH_PRINT_TAGS] is REMOVED rather than emptied: the
   runner tests it with [getenv_opt], so an empty value still selects the tag-printing mode. *)
let run_helper exe =
  let out_file = Filename.temp_file "oth_groups_failure" ".out" in
  let rc =
    Sys.command
      (Printf.sprintf
         "env -u OTH_PRINT_TAGS OTH_TAGS= OTH_EXCLUDE_TAGS= %s > %s 2>&1"
         (Filename.quote exe)
         (Filename.quote out_file))
  in
  let out = CCIO.with_in out_file CCIO.read_all in
  Sys.remove out_file;
  (rc, out)

let () =
  let rc, out = run_helper Sys.argv.(1) in
  print_string out;
  check (Printf.sprintf "the run must exit 1, got %d" rc) (rc = 1);
  holds ~out "Setup failed:";
  (* Every failed setup is reported, not only the first one. *)
  holds ~out "b setup exploded";
  holds ~out "c setup exploded";
  holds ~out "after setup exploded";
  (* A failed setup cannot stop a sibling: group [a] runs its test and tears down. *)
  holds ~out "a_test";
  holds ~out "a_teardown";
  (* A group whose setup failed does not tear down.  This is the contract Oth.Group states, and the
     reason a group setup must release what it took on its own failure path. *)
  absent ~out "b_teardown";
  absent ~out "c_teardown";
  absent ~out "after_teardown";
  (* The run-level teardown still runs. *)
  holds ~out "global_teardown";
  (* The results of the groups that passed are NOT reported: the evaluator gives one [Error] for the
     whole run, so the runner prints the failure instead of the summary. *)
  absent ~out "Tests passed:";
  print_string "groups_failure_test: ok\n"
