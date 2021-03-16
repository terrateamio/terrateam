let test_to_query =
  Oth.test ~desc:"Test to_query" ~name:"to_query" (fun _ ->
      let module Ts = Pgsql_io.Typed_sql in
      let query = Ts.(sql /^ "SELECT foo, bar FROM baz WHERE x = $x" /% Var.smallint "x") in
      let s = Ts.to_query query in
      assert (s = Ok "SELECT foo, bar FROM baz WHERE x = $1"))

let test_to_query_with_ret =
  Oth.test ~desc:"Test to_query with ret" ~name:"to_query with ret" (fun _ ->
      let module Ts = Pgsql_io.Typed_sql in
      let query =
        Ts.(
          sql
          // Ret.text
          // Ret.integer
          /^ "SELECT foo, bar FROM baz WHERE x = $x"
          /% Var.smallint "x")
      in
      let s = Ts.to_query query in
      assert (s = Ok "SELECT foo, bar FROM baz WHERE x = $1"))

let test_query_concat_strings =
  Oth.test ~desc:"Test query concat just strings" ~name:"/^^ strings" (fun _ ->
      let module Ts = Pgsql_io.Typed_sql in
      let q1 = Ts.(sql /^ "hello") in
      let q2 = Ts.(sql /^ "world") in
      let q3 = Ts.(q1 /^^ q2) in
      let s = Ts.to_query q3 in
      assert (s = Ok "hello world"))

let test_query_concat =
  Oth.test ~desc:"Test query concat" ~name:"/^^" (fun _ ->
      let module Ts = Pgsql_io.Typed_sql in
      let q1 = Ts.(sql // Ret.text // Ret.integer /^ "hello" /% Var.integer "x") in
      let q2 = Ts.(sql // Ret.boolean /^ "world" /% Var.text "x") in
      let q3 = Ts.(q1 /^^ q2) in
      let s = Ts.to_query q3 in
      assert (s = Ok "hello world"))

let test_to_query_bad_var =
  Oth.test ~desc:"Test to_query bad var" ~name:"to_query bad var" (fun _ ->
      let module Ts = Pgsql_io.Typed_sql in
      let query = Ts.(sql /^ "SELECT foo, bar FROM baz WHERE x = $y" /% Var.smallint "x") in
      let s = Ts.to_query query in
      assert (s = Error (`Unknown_variable "y")))

let test_to_query_unclosed_single_quote =
  Oth.test ~desc:"Test to_query bad var" ~name:"to_query bad var" (fun _ ->
      let module Ts = Pgsql_io.Typed_sql in
      let query = Ts.(sql /^ "SELECT foo, bar FROM baz WHERE x = '") in
      let s = Ts.to_query query in
      assert (s = Error (`Unclosed_quote "SELECT foo, bar FROM baz WHERE x = '")))

let test_to_query_unclosed_double_quote =
  Oth.test ~desc:"Test to_query bad var" ~name:"to_query bad var" (fun _ ->
      let module Ts = Pgsql_io.Typed_sql in
      let query = Ts.(sql /^ "SELECT foo, bar FROM baz WHERE x = \"") in
      let s = Ts.to_query query in
      assert (s = Error (`Unclosed_quote "SELECT foo, bar FROM baz WHERE x = \"")))

let test_to_query_closed_single_quote =
  Oth.test ~desc:"Test to_query bad var" ~name:"to_query bad var" (fun _ ->
      let module Ts = Pgsql_io.Typed_sql in
      let query = Ts.(sql /^ "SELECT foo, bar FROM baz WHERE x = ''") in
      let s = Ts.to_query query in
      assert (s = Ok "SELECT foo, bar FROM baz WHERE x = ''"))

let test_to_query_closed_double_quote =
  Oth.test ~desc:"Test to_query bad var" ~name:"to_query bad var" (fun _ ->
      let module Ts = Pgsql_io.Typed_sql in
      let query = Ts.(sql /^ "SELECT foo, bar FROM baz WHERE x = \"\"") in
      let s = Ts.to_query query in
      assert (s = Ok "SELECT foo, bar FROM baz WHERE x = \"\""))

let test =
  Oth.parallel
    [
      test_to_query;
      test_to_query_with_ret;
      test_query_concat_strings;
      test_query_concat;
      test_to_query_bad_var;
      test_to_query_unclosed_single_quote;
      test_to_query_unclosed_double_quote;
      test_to_query_closed_single_quote;
      test_to_query_closed_double_quote;
    ]

let () = Oth.run test
