module List = ListLabels

let tests =
  [
    ("foobar", "fo(ob)ar", Some (0, 6), [ (2, 4) ]);
    ("foobar", "(.)(.)", Some (0, 2), [ (0, 1); (1, 2) ]);
    ("foobar", "(.)()", Some (0, 1), [ (0, 1); (1, 1) ]);
    ("123foobar", "(%d+)(%a+)", Some (0, 9), [ (0, 3); (3, 9) ]);
    ("f(o(ob)a)r", "(%b())", Some (1, 9), [ (1, 9) ]);
    ("foobar", "", None, []);
    ( "Z8J(KAWy.yHozCaiY6qn8Sf2(Hs]z$cIEk)x4qq-w3[J3KY1oW6IpIQuok=v1Q$t8i^tmA]5%o.[z3.",
      "[k^av-]3",
      None,
      [] );
    ("/metric/test_metric", "^/metric/([^/]+)$", Some (0, 19), [ (8, 19) ]);
  ]

let compare_mtch res = function
  | None   -> res = None
  | Some m -> res = Some (Lua_pattern.Match.range m)

let compare_captures captures = function
  | None when captures = [] -> true
  | None -> false
  | Some m ->
      let mtch_captures =
        List.map
          ~f:(fun c -> (Lua_pattern.Capture.start c, Lua_pattern.Capture.stop c))
          (Lua_pattern.Match.captures m)
      in
      captures = mtch_captures

let test_mtch str pat res captures _ =
  let pat = CCOption.get_exn_or "lua_pattern_of_string" (Lua_pattern.of_string pat) in
  let mtch = Lua_pattern.mtch str pat in
  assert (compare_mtch res mtch);
  assert (compare_captures captures mtch)

let create_test (str, pat, res, captures) =
  Oth.test ~name:(Printf.sprintf "mtch %s %s" str pat) (test_mtch str pat res captures)

let () = Oth.(run (serial (List.map ~f:create_test tests)))
