let test_resolve_local_file () =
  let tests =
    [
      ( "full URL simple",
        "/foo/bar/baz",
        "https://example.com/images/buzz",
        "/foo/bar/baz/images/buzz" );
      ( "full URL cwd",
        "/foo/bar/baz",
        "https://example.com/./buzz",
        "/foo/bar/baz/buzz" );
      ( "full URL parent blocked",
        "/foo/bar/baz",
        "https://example.com/../buzz",
        "/foo/bar/baz/buzz" );
      ( "full URL grandparent blocked",
        "/foo/bar/baz",
        "https://example.com/../../buzz",
        "/foo/bar/baz/buzz" );
      ( "trailing-slash-docroot full URL simple",
        "/foo/bar/baz/",
        "https://example.com/images/buzz",
        "/foo/bar/baz/images/buzz" );
      ( "trailing-slash-docroot full URL cwd",
        "/foo/bar/baz/",
        "https://example.com/./buzz",
        "/foo/bar/baz/buzz" );
      ( "trailing-slash-docroot full URL parent blocked",
        "/foo/bar/baz/",
        "https://example.com/../buzz",
        "/foo/bar/baz/buzz" );
      ( "trailing-slash-docroot full URL grandparent blocked",
        "/foo/bar/baz/",
        "https://example.com/../../buzz",
        "/foo/bar/baz/buzz" );
      ( "filepath simple",
        "/foo/bar/baz",
        "/images/buzz",
        "/foo/bar/baz/images/buzz" );
      ("filepath cwd", "/foo/bar/baz", "./buzz", "/foo/bar/baz/buzz");
      ("filepath parent blocked", "/foo/bar/baz", "../buzz", "/foo/bar/baz/buzz");
      ( "filepath grandparent blocked",
        "/foo/bar/baz",
        "../../buzz",
        "/foo/bar/baz/buzz" );
      ( "trailing-slash-docroot filepath simple",
        "/foo/bar/baz/",
        "/images/buzz",
        "/foo/bar/baz/images/buzz" );
      ( "trailing-slash-docroot filepath cwd",
        "/foo/bar/baz/",
        "./buzz",
        "/foo/bar/baz/buzz" );
      ( "trailing-slash-docroot filepath parent blocked",
        "/foo/bar/baz/",
        "../buzz",
        "/foo/bar/baz/buzz" );
      ( "trailing-slash-docroot filepath grandparent blocked",
        "/foo/bar/baz/",
        "../../buzz",
        "/foo/bar/baz/buzz" );
      ("root-docroot simple", "/", "/images/buzz", "/images/buzz");
      ("root-docroot cwd", "/", "./buzz", "/buzz");
      ("root-docroot grandparent blocked", "/", "../../buzz", "/buzz");
      ("blank-docroot simple", "", "/images/buzz", "images/buzz");
      ("blank-docroot cwd", "", "./buzz", "buzz");
      ("blank-docroot blank-path", "", "https://example.com", "");
      ("blank-docroot blank-uri", "", "", "");
      ("cwd-docroot simple", ".", "/images/buzz", "./images/buzz");
      ("cwd-docroot cwd", ".", "./buzz", "./buzz");
      ("cwd-docroot blank-path", ".", "https://example.com", "./");
      ("cwd-docroot blank-uri", ".", "", "./");
    ]
  in
  List.iter
    (fun (name, docroot, uri, expected) ->
      Alcotest.(check string)
        name expected
        (Cohttp.Path.resolve_local_file ~docroot ~uri:(Uri.of_string uri)))
    tests

let () = Printexc.record_backtrace true

let () =
  Alcotest.run "test_path"
    [
      ("Path", [ ("Check resolve_local_file", `Quick, test_resolve_local_file) ]);
    ]
