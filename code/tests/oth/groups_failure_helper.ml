(* The failing [Oth.run_groups] run that [groups_failure_test.ml] drives.  It is a separate
   executable because [run_groups] reports a failed group setup and then exits the process: the exit
   code and the printed message are the only observable result, so they have to be read from
   outside.

   Group [a] succeeds.  Groups [b] and [c] fail in their setup, and so does the [?after] group.  What
   the driver asserts about this run, and why, is in [groups_failure_test.ml]. *)

module Oth_abb = Oth_abb.Make (Abb)

let say line =
  print_string (line ^ "\n");
  flush stdout

let ok_group =
  Oth_abb.Group.make
    ~name:"a"
    ~setup:(fun () -> Abb.Future.return (Ok ()))
    ~teardown:(fun () ->
      say "a_teardown";
      Abb.Future.return ())
    (fun () ->
      Oth_abb.test ~name:"a test" (fun () ->
          say "a_test";
          Abb.Future.return ()))

let failing_group name =
  Oth_abb.Group.make
    ~name
    ~setup:(fun () -> Abb.Future.return (Error (name ^ " setup exploded")))
    ~teardown:(fun () ->
      say (name ^ "_teardown");
      Abb.Future.return ())
    (fun () ->
      Oth_abb.test ~name:(name ^ " test") (fun () ->
          say (name ^ "_test");
          Abb.Future.return ()))

let () =
  Logs.set_reporter (Logs_fmt.reporter ());
  Oth_abb.set_default_slots 2;
  Oth_abb.run_groups
    ~file:__FILE__
    ~setup:(fun () -> Abb.Future.return (Ok ()))
    ~teardown:(fun () ->
      say "global_teardown";
      Abb.Future.return ())
    ~after:[ failing_group "after" ]
    [ ok_group; failing_group "b"; failing_group "c" ]
