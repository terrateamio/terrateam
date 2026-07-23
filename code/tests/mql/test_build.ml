module B = Mql.Build

(* The rendered SQL must reparse, because the MQL endpoint parses the query
   string it receives with the same [Mql.Ast.of_string]. *)
let assert_renders sql ast =
  let rendered = Mql.Ast.to_string ast in
  Oth.Assert.Eq.string ~expected:sql ~actual:rendered;
  Oth.Assert.true_ "rendered SQL must reparse" (CCResult.is_ok (Mql.Ast.of_string rendered))

let test =
  Oth.parallel
    [
      Oth.test ~name:"count_star" (fun _ ->
          assert_renders
            "select count(*) from foo"
            (B.select ~from:[ B.table "foo" ] ~cols:(B.columns [ B.col B.count_star ]) ());
          ());
      Oth.test ~name:"in_query" (fun _ ->
          assert_renders
            "select id from foo where id in (select id from bar)"
            (B.select
               ~from:[ B.table "foo" ]
               ~cols:(B.columns [ B.col (B.id "id") ])
               ~where:
                 (B.in_query
                    (B.id "id")
                    (B.select ~from:[ B.table "bar" ] ~cols:(B.columns [ B.col (B.id "id") ]) ()))
               ());
          ());
      Oth.test ~name:"union_all" (fun _ ->
          assert_renders
            "select a from foo union all select b from bar"
            (B.union_all
               (B.select ~from:[ B.table "foo" ] ~cols:(B.columns [ B.col (B.id "a") ]) ())
               (B.select ~from:[ B.table "bar" ] ~cols:(B.columns [ B.col (B.id "b") ]) ()));
          ());
      Oth.test ~name:"union_all chained left with limit" (fun _ ->
          assert_renders
            "select a from foo union all select b from bar union all select c from baz limit 10"
            (Mql.Ast.set_limit
               10
               (B.union_all
                  (B.union_all
                     (B.select ~from:[ B.table "foo" ] ~cols:(B.columns [ B.col (B.id "a") ]) ())
                     (B.select ~from:[ B.table "bar" ] ~cols:(B.columns [ B.col (B.id "b") ]) ()))
                  (B.select ~from:[ B.table "baz" ] ~cols:(B.columns [ B.col (B.id "c") ]) ())));
          ());
    ]

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ test
