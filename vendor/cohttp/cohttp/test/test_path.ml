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
      ( "percent-encoded slash grandparent blocked",
        "/foo/bar/baz",
        "..%2f..%2fbuzz",
        "/foo/bar/baz/buzz" );
      ( "fully percent-encoded grandparent blocked",
        "/foo/bar/baz",
        "%2e%2e%2f%2e%2e%2fbuzz",
        "/foo/bar/baz/buzz" );
      ( "double percent-encoded grandparent blocked",
        "/foo/bar/baz",
        "..%252f..%252fbuzz",
        "/foo/bar/baz/..%2f..%2fbuzz" );
      ( "double fully percent-encoded grandparent blocked",
        "/foo/bar/baz",
        "%252e%252e%252f%252e%252e%252fbuzz",
        "/foo/bar/baz/%2e%2e%2f%2e%2e%2fbuzz" );
      ( "triply percent-encoded grandparent blocked",
        "/foo/bar/baz",
        "..%25252f..%25252fbuzz",
        "/foo/bar/baz/..%252f..%252fbuzz" );
      ( "encoded space preserved",
        "/foo/bar/baz",
        "/my%20file.txt",
        "/foo/bar/baz/my file.txt" );
      ( "encoded utf8 preserved",
        "/foo/bar/baz",
        "/caf%C3%A9.txt",
        "/foo/bar/baz/caf\xc3\xa9.txt" );
      ( "encoded NUL preserved",
        "/foo/bar/baz",
        "/secret%00.txt",
        "/foo/bar/baz/secret\x00.txt" );
      ( "encoded newline preserved",
        "/foo/bar/baz",
        "/a%0ab.txt",
        "/foo/bar/baz/a\nb.txt" );
      ( "encoded DEL preserved",
        "/foo/bar/baz",
        "/a%7fb.txt",
        "/foo/bar/baz/a\x7fb.txt" );
      ( "encoded control does not collapse onto plain name",
        "/foo/bar/baz",
        "/sol%001.html",
        "/foo/bar/baz/sol\x001.html" );
    ]
  in
  List.iter
    (fun (name, docroot, uri, expected) ->
      Alcotest.(check string)
        name expected
        (Cohttp.Path.resolve_local_file ~docroot ~uri:(Uri.of_string uri)))
    tests

let test_normalise () =
  let tests =
    [
      ("relative simple", "/foo/bar", "foo/bar");
      ("relative dot", "/foo/./bar", "foo/bar");
      ("relative grandparent blocked", "/../../etc/passwd", "etc/passwd");
      ("encoded slash traversal blocked", "/..%2f..%2fetc/passwd", "etc/passwd");
      ( "absolute-form grandparent blocked",
        "http://host/../../etc/passwd",
        "etc/passwd" );
      ( "absolute-form deep grandparent blocked",
        "https://example.com/a/../../../../etc/shadow",
        "etc/shadow" );
      ("root path empty", "/", "");
      ("empty path", "", "");
      ("trailing slash dropped", "/foo/bar/", "foo/bar");
      ("encoded trailing slash dropped", "/foo/bar%2f", "foo/bar");
      ("empty segments collapsed", "/foo//bar", "foo/bar");
      ("encoded control preserved", "/sol%001.html", "sol\x001.html");
      ("plain slash separator", "/private/secret.txt", "private/secret.txt");
      ( "backslash preserved, distinct from slash",
        "/private%5csecret.txt",
        "private\\secret.txt" );
      ( "encoded backslash traversal preserved verbatim",
        "/..%5c..%5cwindows",
        "..\\..\\windows" );
    ]
  in
  List.iter
    (fun (name, uri, expected) ->
      Alcotest.(check string)
        name expected
        (Cohttp.Path.normalise (Uri.of_string uri)))
    tests

let () = Printexc.record_backtrace true

let () =
  Alcotest.run "test_path"
    [
      ( "Path",
        [
          ("Check resolve_local_file", `Quick, test_resolve_local_file);
          ("Check normalise", `Quick, test_normalise);
        ] );
    ]
