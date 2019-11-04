module Test = Abb_test.Make (Abb_scheduler_select)

let () = Test.run_tests ()
