let homepage_rt = Furi.rel
let homepage_slash_rt = Furi.(rel / "")
let hello_rt = Furi.(rel / "hello" /% Path.string)
let goodbye_rt = Furi.(rel / "goodbye" /% Path.string)
let extra_rt = Furi.(rel / "extra" /% Path.any)
let any_rt = Furi.(rel /% Path.any)
let query_rt = Furi.(rel /? Query.string "name")
let fragment_rt = Furi.(rel /$ Fragment.string)
let path_var = Furi.(rel / "test" /% Path.string)
let query_var = Furi.(rel / "test" /? Query.string "test")
let path_with_slash = Furi.(rel / "with/slash")
let handle_hello_name = Printf.sprintf "Hello %s"
let handle_goodbye_name = Printf.sprintf "Goodbye %s"
let handle_extra = Printf.sprintf "Extra %s"
let handle_homepage = Printf.sprintf "Homepage"
let handle_homepage_slash = Printf.sprintf "Homepage Slash"
let handle_query = Printf.sprintf "Query %s"
let get_value = CCFun.id

let router ?must_consume_path =
  Furi.(
    route_uri
      ?must_consume_path
      ~default:(fun _ -> failwith "This is not a valid path.")
      [
        fragment_rt --> get_value;
        query_var --> get_value;
        path_var --> get_value;
        path_with_slash --> "path_with_slash";
        query_rt --> handle_query;
        hello_rt --> handle_hello_name;
        goodbye_rt --> handle_goodbye_name;
        extra_rt --> handle_extra;
        homepage_rt --> handle_homepage;
        homepage_slash_rt --> handle_homepage_slash;
      ])

let any_router =
  Furi.(
    route_uri ~default:(fun _ -> failwith "This is not a valid path.") [ any_rt --> handle_extra ])

let route_hello =
  Oth.test ~desc:"Route to the hello path" ~name:"Route hello" (fun _ ->
      let uri = Uri.of_string "http://test.com/hello/there" in
      let resp = router uri in
      assert (resp = "Hello there"))

let route_hello_no_host =
  Oth.test ~desc:"Route to the hello path no host" ~name:"Route hello no host" (fun _ ->
      let uri = Uri.of_string "/hello/there" in
      let resp = router uri in
      assert (resp = "Hello there"))

let route_no_must_consume_path =
  Oth.test ~desc:"Must not consume path" ~name:"No Consume Path" (fun _ ->
      let uri = Uri.of_string "http://test.com/hello/there/test" in
      let resp = router ~must_consume_path:false uri in
      assert (resp = "Hello there"))

let route_goodbye =
  Oth.test ~desc:"Route to the goodbye path" ~name:"Route goodbye" (fun _ ->
      let uri = Uri.of_string "http://test.com/goodbye/you" in
      let resp = router uri in
      assert (resp = "Goodbye you"))

let route_extra =
  Oth.test ~desc:"Route with extra path" ~name:"Route extra" (fun _ ->
      let uri = Uri.of_string "http://test.com/extra/there/boss/man" in
      let resp = router uri in
      assert (resp = "Extra there/boss/man"))

let route_extra_with_encoded_chars =
  Oth.test ~desc:"Route with extra path with encoded chares" ~name:"Route extra encoded" (fun _ ->
      let uri = Uri.of_string "http://test.com/extra/there/boss/m an" in
      let resp = router uri in
      assert (resp = "Extra there/boss/m an"))

let route_extra_no_extra =
  Oth.test
    ~desc:"Route with extra path but none exists in URL"
    ~name:"Route extra no extra"
    (fun _ ->
      let uri = Uri.of_string "http://test.com/extra" in
      try
        ignore (router uri);
        assert false
      with Failure msg -> assert (msg = "This is not a valid path."))

let route_extra_just_slash =
  Oth.test ~desc:"Route with extra path but just ends in slash" ~name:"Route extra slash" (fun _ ->
      let uri = Uri.of_string "http://test.com/extra/" in
      let resp = router uri in
      assert (resp = "Extra "))

let route_any =
  Oth.test ~desc:"Route any" ~name:"Route any" (fun _ ->
      let uri = Uri.of_string "http://test.com/any/there/boss/man" in
      let resp = any_router uri in
      assert (resp = "Extra any/there/boss/man"))

let route_any_no_extra =
  Oth.test ~desc:"Route with just host" ~name:"Route any just host" (fun _ ->
      let uri = Uri.of_string "http://test.com" in
      try
        ignore (any_router uri);
        assert false
      with Failure msg -> assert (msg = "This is not a valid path."))

let route_any_just_slash =
  Oth.test ~desc:"Route with any with slash" ~name:"Route any just slash" (fun _ ->
      let uri = Uri.of_string "http://test.com/" in
      let resp = any_router uri in
      assert (resp = "Extra "))

let route_homepage =
  Oth.test ~desc:"Route to the homepage path" ~name:"Route homepage" (fun _ ->
      let uri = Uri.of_string "http://test.com" in
      let resp = router uri in
      assert (resp = "Homepage"))

let route_homepage_slash =
  Oth.test
    ~desc:"Route to the homepage path with ending slash"
    ~name:"Route homepage slash"
    (fun _ ->
      let uri = Uri.of_string "http://test.com/" in
      let resp = router uri in
      assert (resp = "Homepage Slash"))

let route_homepage_slash_rel =
  Oth.test
    ~desc:"Route to the homepage path with ending slash"
    ~name:"Route homepage slash Rel"
    (fun _ ->
      let uri = Uri.of_string "/" in
      let resp = router uri in
      assert (resp = "Homepage Slash"))

let route_query =
  Oth.test ~desc:"Route with query" ~name:"Route query" (fun _ ->
      let uri = Uri.of_string "http://test.com?name=foobar" in
      let resp = router uri in
      assert (resp = "Query foobar"))

let route_fragment =
  Oth.test ~desc:"Route to fragment" ~name:"Route fragment" (fun _ ->
      let uri = Uri.of_string "http://test.com/hello/there#testing" in
      let resp = router ~must_consume_path:false uri in
      assert (resp = "testing"))

let match_hello =
  Oth.test ~desc:"Match hello path" ~name:"Match hello" (fun _ ->
      let uri = Uri.of_string "http://test.com/hello/there" in
      match Furi.(match_uri (hello_rt --> handle_hello_name) uri) with
      | Some m ->
          let resp = Furi.Match.apply m in
          assert (resp = "Hello there")
      | None -> assert false)

let match_fail =
  Oth.test ~desc:"Ensure match fails" ~name:"Match fail" (fun _ ->
      let uri = Uri.of_string "http://test.com/goodbye/there" in
      let ret = Furi.(match_uri (hello_rt --> handle_hello_name) uri) in
      assert (ret = None))

let match_no_consume_path =
  Oth.test ~desc:"Match without consuming entire path" ~name:"Match no consume" (fun _ ->
      let uri = Uri.of_string "http://test.com/hello/there/bar/baz" in
      match Furi.(match_uri ~must_consume_path:false (hello_rt --> handle_hello_name) uri) with
      | Some m ->
          let resp = Furi.Match.apply m in
          assert (resp = "Hello there");
          assert (Furi.Match.consumed_path m = "/hello/there");
          assert (Furi.Match.remaining_path m = "/bar/baz")
      | None -> assert false)

let match_prefix =
  Oth.test ~desc:"Match prefix" ~name:"Match prefix" (fun _ ->
      let uri = Uri.of_string "http://test.com/hello/there" in
      let rt = Furi.(root "/hello" /% Path.string) in
      match Furi.(match_uri (rt --> handle_hello_name) uri) with
      | Some m ->
          let resp = Furi.Match.apply m in
          assert (resp = "Hello there")
      | None -> assert false)

let match_path_equal =
  Oth.test ~name:"Match path equal" (fun _ ->
      let uri = Uri.of_string "http://test.com/hello/there" in
      let rt = Furi.(root "/hello" /% Path.string) in
      match Furi.(match_uri (rt --> handle_hello_name) uri) with
      | Some m -> assert (Furi.Match.equal m m)
      | None -> assert false)

let match_path_not_equal =
  Oth.test ~name:"Match path not equal" (fun _ ->
      let uri1 = Uri.of_string "http://test.com/hello/there" in
      let uri2 = Uri.of_string "http://test.com/hello/you" in
      let rt = Furi.(root "/hello" /% Path.string) in
      match
        Furi.(match_uri (rt --> handle_hello_name) uri1, match_uri (rt --> handle_hello_name) uri2)
      with
      | Some m1, Some m2 -> assert (not (Furi.Match.equal m1 m2))
      | _ -> assert false)

let match_query_equal =
  Oth.test ~name:"Match query equal" (fun _ ->
      let uri = Uri.of_string "http://test.com?q=foo" in
      let rt = Furi.(rel /? Query.string "q") in
      match Furi.(match_uri (rt --> fun _ -> ()) uri) with
      | Some m -> assert (Furi.Match.equal m m)
      | None -> assert false)

let match_query_not_equal =
  Oth.test ~name:"Match query not equal" (fun _ ->
      let uri1 = Uri.of_string "http://test.com?q=foo" in
      let uri2 = Uri.of_string "http://test.com?q=bar" in
      let rt = Furi.(rel /? Query.string "q") in
      match Furi.(match_uri (rt --> fun _ -> ()) uri1, match_uri (rt --> fun _ -> ()) uri2) with
      | Some m1, Some m2 -> assert (not (Furi.Match.equal m1 m2))
      | _ -> assert false)

let match_query_equal_but_different =
  Oth.test ~name:"Match query equal but different" (fun _ ->
      let uri1 = Uri.of_string "http://test.com?q=foo" in
      let uri2 = Uri.of_string "http://test.com?q=foo,bar" in
      let rt = Furi.(rel /? Query.string "q") in
      match Furi.(match_uri (rt --> fun _ -> ()) uri1, match_uri (rt --> fun _ -> ()) uri2) with
      | Some m1, Some m2 -> assert (not (Furi.Match.equal m1 m2))
      | _ -> assert false)

let match_query_order_does_not_matter =
  Oth.test ~name:"Match query order does not matter" (fun _ ->
      let uri1 = Uri.of_string "http://test.com?a=foo&b=bar" in
      let uri2 = Uri.of_string "http://test.com?b=bar&a=foo" in
      let rt = Furi.(rel /? Query.string "a" /? Query.string "b") in
      match Furi.(match_uri (rt --> fun _ _ -> ()) uri1, match_uri (rt --> fun _ _ -> ()) uri2) with
      | Some m1, Some m2 -> assert (Furi.Match.equal m1 m2)
      | _ -> assert false)

let match_path_consumption =
  Oth.test ~name:"Match path consumption not equal" (fun _ ->
      let uri = Uri.of_string "http://test.com/foo/bar" in
      let rt1 = Furi.(rel / "foo" / "bar") in
      let rt2 = Furi.(rel /% Path.string /% Path.string) in
      match Furi.(match_uri (rt1 --> ()) uri, match_uri (rt2 --> fun _ _ -> ()) uri) with
      | Some m1, Some m2 -> assert (not (Furi.Match.equal m1 m2))
      | _ -> assert false)

let match_fragment_equal =
  Oth.test ~name:"Match fragment equal" (fun _ ->
      let uri = Uri.of_string "http://test.com#foo" in
      let rt = Furi.(rel /$ Fragment.string) in
      match Furi.(match_uri (rt --> fun _ -> ()) uri) with
      | Some m -> assert (Furi.Match.equal m m)
      | None -> assert false)

let match_fragment_not_equal =
  Oth.test ~name:"Match fragment not equal" (fun _ ->
      let uri1 = Uri.of_string "http://test.com#foo" in
      let uri2 = Uri.of_string "http://test.com#bar" in
      let rt = Furi.(rel /$ Fragment.string) in
      match Furi.(match_uri (rt --> fun _ -> ()) uri1, match_uri (rt --> fun _ -> ()) uri2) with
      | Some m1, Some m2 -> assert (not (Furi.Match.equal m1 m2))
      | _ -> assert false)

let first_match_slash_rel =
  Oth.test ~desc:"first_match" ~name:"First match homepage slash Rel" (fun _ ->
      let uri = Uri.of_string "/" in
      match
        Furi.first_match
          Furi.
            [
              query_rt --> handle_query;
              hello_rt --> handle_hello_name;
              goodbye_rt --> handle_goodbye_name;
              extra_rt --> handle_extra;
              homepage_rt --> handle_homepage;
              homepage_slash_rt --> handle_homepage_slash;
            ]
          uri
      with
      | Some v -> assert (Furi.Match.apply v = handle_homepage_slash)
      | None -> assert false)

let test_path_const_with_slash =
  Oth.test ~desc:"Test path const with slash" ~name:"Path const slash" (fun _ ->
      let uri =
        Uri.(with_path (of_string "http://test.com") (pct_encode ~component:`Path "with/slash"))
      in
      assert (router uri = "path_with_slash"))

let test_path_with_space =
  Oth.test ~desc:"Test path var with space" ~name:"Path var space" (fun _ ->
      let uri = Uri.of_string "http://test.com/test/with space" in
      assert (router uri = "with space"))

let test_path_with_slash =
  Oth.test ~desc:"Test path var with slash" ~name:"Path var slash" (fun _ ->
      let uri =
        Uri.(
          with_path
            (of_string "http://test.com")
            ("/test/" ^ pct_encode ~component:`Path "with/slash"))
      in
      assert (router uri = "with/slash"))

let test_query_with_space =
  Oth.test ~desc:"Test query var with space" ~name:"Query var space" (fun _ ->
      let uri =
        Uri.add_query_param' (Uri.of_string "http://test.com/test") ("test", "with space")
      in
      assert (router uri = "with space"))

let test_query_with_plus =
  Oth.test ~desc:"Test query var with plus" ~name:"Query var plus" (fun _ ->
      let uri =
        Uri.add_query_param' (Uri.of_string "http://test.com/test") ("test", "with + plus")
      in
      assert (router uri = "with + plus"))

let test_query_with_and =
  Oth.test ~desc:"Test query var with &" ~name:"Query var ampersand" (fun _ ->
      let uri =
        Uri.add_query_param' (Uri.of_string "http://test.com/test") ("test", "with & and")
      in
      assert (router uri = "with & and"))

let test =
  Oth.parallel
    [
      route_hello;
      route_hello_no_host;
      route_no_must_consume_path;
      route_goodbye;
      route_extra;
      route_extra_with_encoded_chars;
      route_extra_no_extra;
      route_extra_just_slash;
      route_any;
      route_any_no_extra;
      route_any_no_extra;
      route_homepage;
      route_homepage_slash;
      route_homepage_slash_rel;
      route_query;
      route_fragment;
      match_hello;
      match_fail;
      match_no_consume_path;
      match_prefix;
      match_path_equal;
      match_path_not_equal;
      match_query_equal;
      match_query_not_equal;
      match_query_equal_but_different;
      match_query_order_does_not_matter;
      match_path_consumption;
      match_fragment_equal;
      match_fragment_not_equal;
      first_match_slash_rel;
      test_path_const_with_slash;
      test_path_with_space;
      test_path_with_slash;
      test_query_with_space;
      test_query_with_plus;
      test_query_with_and;
    ]

let () =
  Random.self_init ();
  Oth.run test
