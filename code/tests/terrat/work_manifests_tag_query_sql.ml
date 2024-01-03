module Tag_query_sql = Terrat_ep_installations.Work_manifests.Tag_query_sql

let test_simple_pr =
  Oth.test ~name:"Simple pr" (fun _ ->
      let tq = "pr:123" in
      match Terrat_tag_query_ast.of_string tq with
      | Ok (Some ast) -> (
          let t = Tag_query_sql.empty () in
          match Tag_query_sql.(of_ast t ast) with
          | Ok () -> assert (Buffer.contents t.Tag_query_sql.q = "pull_number = ($bigints)[1]")
          | Error _ -> assert false)
      | Ok None -> assert false
      | Error _ -> assert false)

let test_simple_user =
  Oth.test ~name:"Simple user" (fun _ ->
      let tq = "user:foo" in
      match Terrat_tag_query_ast.of_string tq with
      | Ok (Some ast) -> (
          let t = Tag_query_sql.empty () in
          match Tag_query_sql.(of_ast t ast) with
          | Ok () -> assert (Buffer.contents t.Tag_query_sql.q = "username = ($strings)[1]")
          | Error _ -> assert false)
      | Ok None -> assert false
      | Error _ -> assert false)

let test_simple_dir =
  Oth.test ~name:"Simple dir" (fun _ ->
      let tq = "dir:foo" in
      match Terrat_tag_query_ast.of_string tq with
      | Ok (Some ast) -> (
          let t = Tag_query_sql.empty () in
          match Tag_query_sql.(of_ast t ast) with
          | Ok () ->
              assert (Buffer.contents t.Tag_query_sql.q = "(dirspaces @> (($json)[1]::jsonb))")
          | Error _ -> assert false)
      | Ok None -> assert false
      | Error _ -> assert false)

let test_simple_repo =
  Oth.test ~name:"Simple repo" (fun _ ->
      let tq = "repo:foo" in
      match Terrat_tag_query_ast.of_string tq with
      | Ok (Some ast) -> (
          let t = Tag_query_sql.empty () in
          match Tag_query_sql.(of_ast t ast) with
          | Ok () -> assert (Buffer.contents t.Tag_query_sql.q = "name = ($strings)[1]")
          | Error _ -> assert false)
      | Ok None -> assert false
      | Error _ -> assert false)

let test_simple_type =
  Oth.test ~name:"Simple type" (fun _ ->
      let tq = "type:foo" in
      match Terrat_tag_query_ast.of_string tq with
      | Ok (Some ast) -> (
          let t = Tag_query_sql.empty () in
          match Tag_query_sql.(of_ast t ast) with
          | Ok () -> assert (Buffer.contents t.Tag_query_sql.q = "run_type = ($strings)[1]")
          | Error _ -> assert false)
      | Ok None -> assert false
      | Error _ -> assert false)

let test_simple_state =
  Oth.test ~name:"Simple state" (fun _ ->
      let tq = "state:foo" in
      match Terrat_tag_query_ast.of_string tq with
      | Ok (Some ast) -> (
          let t = Tag_query_sql.empty () in
          match Tag_query_sql.(of_ast t ast) with
          | Ok () -> assert (Buffer.contents t.Tag_query_sql.q = "state = ($strings)[1]")
          | Error _ -> assert false)
      | Ok None -> assert false
      | Error _ -> assert false)

let test_simple_branch =
  Oth.test ~name:"Simple branch" (fun _ ->
      let tq = "branch:foo" in
      match Terrat_tag_query_ast.of_string tq with
      | Ok (Some ast) -> (
          let t = Tag_query_sql.empty () in
          match Tag_query_sql.(of_ast t ast) with
          | Ok () -> assert (Buffer.contents t.Tag_query_sql.q = "branch = ($strings)[1]")
          | Error _ -> assert false)
      | Ok None -> assert false
      | Error _ -> assert false)

let test_simple_workspace =
  Oth.test ~name:"Simple workspace" (fun _ ->
      let tq = "workspace:foo" in
      match Terrat_tag_query_ast.of_string tq with
      | Ok (Some ast) -> (
          let t = Tag_query_sql.empty () in
          match Tag_query_sql.(of_ast t ast) with
          | Ok () ->
              assert (Buffer.contents t.Tag_query_sql.q = "(dirspaces @> (($json)[1]::jsonb))")
          | Error _ -> assert false)
      | Ok None -> assert false
      | Error _ -> assert false)

let test_simple_not =
  Oth.test ~name:"Simple not" (fun _ ->
      let tq = "not branch:foo" in
      match Terrat_tag_query_ast.of_string tq with
      | Ok (Some ast) -> (
          let t = Tag_query_sql.empty () in
          match Tag_query_sql.(of_ast t ast) with
          | Ok () -> assert (Buffer.contents t.Tag_query_sql.q = "not (branch = ($strings)[1])")
          | Error _ -> assert false)
      | Ok None -> assert false
      | Error _ -> assert false)

let test_and =
  Oth.test ~name:"And" (fun _ ->
      let tq = "pr:123 and user:foo" in
      match Terrat_tag_query_ast.of_string tq with
      | Ok (Some ast) -> (
          let t = Tag_query_sql.empty () in
          match Tag_query_sql.(of_ast t ast) with
          | Ok () ->
              assert (
                Buffer.contents t.Tag_query_sql.q
                = "(pull_number = ($bigints)[1]) and (username = ($strings)[1])")
          | Error _ -> assert false)
      | Ok None -> assert false
      | Error _ -> assert false)

let test_or =
  Oth.test ~name:"Or" (fun _ ->
      let tq = "pr:123 or user:foo" in
      match Terrat_tag_query_ast.of_string tq with
      | Ok (Some ast) -> (
          let t = Tag_query_sql.empty () in
          match Tag_query_sql.(of_ast t ast) with
          | Ok () ->
              assert (
                Buffer.contents t.Tag_query_sql.q
                = "(pull_number = ($bigints)[1]) or (username = ($strings)[1])")
          | Error _ -> assert false)
      | Ok None -> assert false
      | Error _ -> assert false)

let test_complex =
  Oth.test ~name:"Complex" (fun _ ->
      let tq = "pr:123 and (user:foo or user:bar)" in
      match Terrat_tag_query_ast.of_string tq with
      | Ok (Some ast) -> (
          let t = Tag_query_sql.empty () in
          match Tag_query_sql.(of_ast t ast) with
          | Ok () ->
              assert (
                Buffer.contents t.Tag_query_sql.q
                = "(pull_number = ($bigints)[1]) and ((username = ($strings)[1]) or (username = \
                   ($strings)[2]))")
          | Error _ -> assert false)
      | Ok None -> assert false
      | Error _ -> assert false)

let test =
  Oth.parallel
    [
      test_simple_pr;
      test_simple_user;
      test_simple_dir;
      test_simple_repo;
      test_simple_type;
      test_simple_state;
      test_simple_branch;
      test_simple_workspace;
      test_simple_not;
      test_and;
      test_or;
    ]

let () =
  Random.self_init ();
  Oth.run test
