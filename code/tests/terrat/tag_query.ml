let test_simple_match =
  Oth.test ~name:"Simple match" (fun _ ->
      let query = Terrat_tag_query.of_string "a" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      assert (Terrat_tag_query.match_ ~tag_set ~dirspace query))

let test_simple_no_match =
  Oth.test ~name:"Simple no match" (fun _ ->
      let query = Terrat_tag_query.of_string "d" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      assert (not (Terrat_tag_query.match_ ~tag_set ~dirspace query)))

let test_simple_and =
  Oth.test ~name:"Simple and" (fun _ ->
      let query = Terrat_tag_query.of_string "a b" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      assert (Terrat_tag_query.match_ ~tag_set ~dirspace query))

let test_dir_glob_at_start =
  Oth.test ~name:"Simple Dir glob at start" (fun _ ->
      let query = Terrat_tag_query.of_string "dir~foo" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      assert (Terrat_tag_query.match_ ~tag_set ~dirspace query))

let test_dir_glob_inner =
  Oth.test ~name:"Simple Dir glob inner" (fun _ ->
      let query = Terrat_tag_query.of_string "dir~bar" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      assert (Terrat_tag_query.match_ ~tag_set ~dirspace query))

let test_dir_glob_at_end =
  Oth.test ~name:"Simple Dir glob at end" (fun _ ->
      let query = Terrat_tag_query.of_string "dir~zoom" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      assert (Terrat_tag_query.match_ ~tag_set ~dirspace query))

let test_dir_glob_cross_dirs =
  Oth.test ~name:"Simple Dir glob cross dirs" (fun _ ->
      let query = Terrat_tag_query.of_string "dir~bar/baz" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      assert (Terrat_tag_query.match_ ~tag_set ~dirspace query))

let test_dir_glob_not_match_partial =
  Oth.test ~name:"Simple Dir glob does not match partial" (fun _ ->
      let query = Terrat_tag_query.of_string "dir~az" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      assert (not (Terrat_tag_query.match_ ~tag_set ~dirspace query)))

let test_dir_glob_no_match_with_slashes =
  Oth.test ~name:"Simple Dir glob does no match with slashes" (fun _ ->
      let query = Terrat_tag_query.of_string "dir~/bar/" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      assert (not (Terrat_tag_query.match_ ~tag_set ~dirspace query)))

let test_bad_glob =
  Oth.test ~name:"Bad glob" (fun _ ->
      let query = Terrat_tag_query.of_string "dir~ba*r" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      assert (not (Terrat_tag_query.match_ ~tag_set ~dirspace query)))

let test_query_with_extra_spaces =
  Oth.test ~name:"Query with extra spaces" (fun _ ->
      let query = Terrat_tag_query.of_string "a                  b" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      assert (Terrat_tag_query.match_ ~tag_set ~dirspace query))

let test_complex_query_match =
  Oth.test ~name:"Complex query match" (fun _ ->
      let query = Terrat_tag_query.of_string "a                  b   dir~bar/baz" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      assert (Terrat_tag_query.match_ ~tag_set ~dirspace query))

let test_complex_query_no_match =
  Oth.test ~name:"Complex query no match" (fun _ ->
      let query = Terrat_tag_query.of_string "a                  b   dir~bar/baz1" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      assert (not (Terrat_tag_query.match_ ~tag_set ~dirspace query)))

let test_empty_query =
  Oth.test ~name:"Empty query" (fun _ ->
      let query = Terrat_tag_query.of_string "" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      assert (Terrat_tag_query.match_ ~tag_set ~dirspace query))

let test_to_string =
  Oth.test ~name:"To string" (fun _ ->
      let query = Terrat_tag_query.of_string "a                  b   dir~bar/baz" in
      assert (Terrat_tag_query.to_string query = "a b dir~bar/baz"))

let test =
  Oth.parallel
    [
      test_simple_match;
      test_simple_no_match;
      test_simple_and;
      test_dir_glob_at_start;
      test_dir_glob_inner;
      test_dir_glob_at_end;
      test_dir_glob_cross_dirs;
      test_dir_glob_not_match_partial;
      test_dir_glob_no_match_with_slashes;
      test_bad_glob;
      test_query_with_extra_spaces;
      test_complex_query_match;
      test_complex_query_no_match;
      test_empty_query;
      test_to_string;
    ]

let () =
  Random.self_init ();
  Oth.run test
