module List = ListLabels

let tests =
  [
    ("o", true);
    ("%a", true);
    ("fu?", true);
    ("o+", true);
    ("%a+", true);
    ("%a*", true);
    ("%d*%a+", true);
    ("fo.b.r", true);
    ("%D+%d+", true);
    ("[ba]", true);
    ("[ba]+", true);
    ("[0-9]+foobar", true);
    ("^foobar$", true);
    ("$bar", true);
    ("/%*.*%*/", true);
    ("/%*.-%*/", true);
    ("(%a+)", true);
    ("%b()", true);
    ("%b(", false);
    ("[fobar", false);
    ("fobar]", true);
    ("[^a-z]+[0-9]+foobar$", true);
    ("[a-z%%]+", true);
    ("%", false);
    ("", true);
    ("(", false);
    (")", false);
    (")(", false);
    ("([fb-c[)E", false);
  ]

let test_pat pat res _ = assert (res = CCOpt.is_some (Lua_pattern.of_string pat))

let create_test (pat, res) = Oth.test ~name:(Printf.sprintf "%s" pat) (test_pat pat res)

let () = Oth.(run (serial (List.map ~f:create_test tests)))
