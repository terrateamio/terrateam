module List = ListLabels

let tests =
  [
    ("foobar", "foobar", "fubar", Some "fubar");
    ("foobar", "%a+", "bum", Some "bum");
    ("foobar", "oo", "u", Some "fubar");
    ("123foobar", "(%d+)(%a+)", "%2%1", Some "foobar123");
    ("f(o(ob)a)r", "%b()", "", Some "fr");
    ("\"foobar\"", "%b\"\"", "", None);
  ]

let compare_res = ( = )

let test_subs str pat subs res _ =
  let pat = CCOpt.get_exn (Lua_pattern.of_string pat) in
  let ret = Lua_pattern.substitute ~s:str ~r:(Lua_pattern.rep_str subs) pat in
  assert (compare_res ret res)

let create_test (str, pat, subs, res) =
  Oth.test ~name:(Printf.sprintf "substitue %s %s" str pat) (test_subs str pat subs res)

let () = Oth.(run (serial (List.map ~f:create_test tests)))
