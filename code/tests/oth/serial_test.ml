module List = ListLabels

let not_in_test = 0
let in_test = 1

let tracker = ref not_in_test

let serial_test _ =
  assert (!tracker = not_in_test);
  tracker := in_test;
  assert (!tracker = in_test);
  tracker := not_in_test;
  ()

let () =
  Oth.(
    run
      (serial
         (List.map
            ~f:(test ~name:"Serial Test")
            [ serial_test
            ; serial_test
            ; serial_test
            ; serial_test
            ; serial_test
            ])))
