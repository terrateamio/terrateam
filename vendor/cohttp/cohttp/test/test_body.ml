let test_if_body_empty () =
  let tests =
    Cohttp.Body.
      [
        ("empty string", of_string "", true);
        ("empty list of strings", of_string_list [], true);
        ("list of strings with empty bytes", of_string_list [ ""; ""; "" ], true);
        ("non empty list of strings", of_string_list [ ""; "foo"; "bar" ], false);
      ]
  in
  List.iter
    (fun (name, body, expected) ->
      Alcotest.(check bool) name (Cohttp.Body.is_empty body) expected)
    tests

let () = Printexc.record_backtrace true

let () =
  Alcotest.run "test_body"
    [
      ( "Query body information",
        [ ("Check if body is empty", `Quick, test_if_body_empty) ] );
    ]
