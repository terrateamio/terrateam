module List = ListLabels

let tests =
  [ ("foobar", "o", Some (1, 2))
  ; ("foobar", "foobarbaz", None)
  ; ("foobar", "%a", Some (0, 1))
  ; ("foobar", "fu?", Some (0, 1))
  ; ("foobar", "fo?", Some (0, 2))
  ; ("foobar", "o+", Some (1, 3))
  ; ("foobar", "%a+", Some (0, 6))
  ; ("foobar", "%a*", Some (0, 6))
  ; ("foobar", "%d*%a+", Some (0, 6))
  ; ("123foobar", "%d*%a+", Some (0, 9))
  ; ("123foobar", "%d*%a+%d", None)
  ; ("foobar", "fo.b.r", Some (0, 6))
  ; ("fubar", "fobar", None)
  ; ("foobar123", "%D+%d+", Some (0, 9))
  ; ("foobar", "[ba]", Some (3, 4))
  ; ("foobar", "[ba]+", Some (3, 5))
  ; ("123foobar", "[0-9]+foobar", Some (0, 9))
  ; ("foobar", "^foobar$", Some (0, 6))
  ; ("foo$bar", "$bar", Some (3, 7))
  ; ("int x; /* x */  int y; /* y */", "/%*.*%*/", Some (7, 30))
  ; ("int x; /* x */  int y; /* y */", "/%*.-%*/", Some (7, 14))
  ; ("foobar", "(%a+)", Some (0, 6))
  ; ("f(ooba)r", "%b()", Some (1, 7))
  ; ("f(o(ob)a)r", "%b()", Some (1, 9))
  ; ("foobar", "[fobar]", Some (0, 1))
  ; ("foobar", "[^fobar]", None)
  ; ("123foobar", "[^a-z]+[0-9]+foobar$", Some (0, 9))
  ; ("foo%bar", "[a-z%%]+", Some (0, 7))
  ; ("7EFwVe][]6[RjmerSSaNllD=$my%*0r.r*r(On2", "[2]%bfTM", None)
  ; ("2", "[2]%bfTM", None)
  ]

let compare_res = (=)

let test_pat str pat res _ =
  let pat = CCOpt.get_exn (Lua_pattern.of_string pat) in
  let mtch = Lua_pattern.find str pat in
  assert (compare_res res mtch)

let create_test (str, pat, res) =
  Oth.test ~name:(Printf.sprintf "find %s %s" str pat) (test_pat str pat res)

let () =
  Oth.(
    run
      (serial
         (List.map ~f:create_test tests)))
