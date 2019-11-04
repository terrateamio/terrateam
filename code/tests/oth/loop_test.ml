let iterations = 100

let loops = ref 0

let loop_test _ =
  loops := !loops + 1;
  ()

let validate_loops _ =
  assert (!loops = iterations);
  ()

let () =
  Oth.(
    run
      (serial
         [
           name ~name:"Loop Test" (silent (loop iterations (test ~name:"Loop test" loop_test)));
           test ~name:"Validate loop" validate_loops;
         ]))
