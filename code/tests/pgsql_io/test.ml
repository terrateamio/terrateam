let test_to_query =
  Oth.test ~desc:"Test to_query" ~name:"to_query" (fun _ ->
      let module Ts = Pgsql_io.Typed_sql in
      let query = Ts.(sql /^ "SELECT foo, bar FROM baz WHERE x = $1" /% Var.smallint) in
      let s = Ts.to_query query in
      assert (s = "SELECT foo, bar FROM baz WHERE x = $1"))

let test_to_query_with_ret =
  Oth.test ~desc:"Test to_query with ret" ~name:"to_query with ret" (fun _ ->
      let module Ts = Pgsql_io.Typed_sql in
      let query =
        Ts.(
          sql // Ret.text // Ret.integer /^ "SELECT foo, bar FROM baz WHERE x = $1" /% Var.smallint)
      in
      let s = Ts.to_query query in
      assert (s = "SELECT foo, bar FROM baz WHERE x = $1"))

let test = Oth.parallel [ test_to_query; test_to_query_with_ret ]

let () = Oth.run test
