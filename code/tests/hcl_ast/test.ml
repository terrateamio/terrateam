let make_success_test_expected path =
  Oth.test
    ~name:(Filename.basename path ^ ".expected")
    (fun _ ->
      let contents = CCIO.with_in path CCIO.read_all in
      match Hcl_ast.of_string contents with
      | Ok ast ->
          CCIO.with_out
            (path ^ ".expected")
            (CCFun.flip CCIO.write_line (Yojson.Safe.pretty_to_string (Hcl_ast.to_yojson ast)))
      | Error (#Hcl_ast.err as err) -> raise (Failure (Hcl_ast.show_err err)))

let make_fail_test_expected path =
  Oth.test
    ~name:(Filename.basename path ^ ".expected")
    (fun _ ->
      let contents = CCIO.with_in path CCIO.read_all in
      (* Multiple tests can be in a file separated by three dashes.  All tests
         have the same failure *)
      let contents =
        match CCString.split ~by:"\n---\n" contents with
        | contents :: _ -> contents
        | [] -> assert false
      in
      match Hcl_ast.of_string contents with
      | Ok _ -> assert false
      | Error (`Error (_, _, msg)) ->
          CCIO.with_out (path ^ ".expected") (CCFun.flip CCIO.write_line msg))

let make_success_test path =
  Oth.test ~name:(Filename.basename path) (fun _ ->
      let contents = CCIO.with_in path CCIO.read_all in
      match Hcl_ast.of_string contents with
      | Ok ast -> (
          match
            Hcl_ast.of_yojson
              (Yojson.Safe.from_string (CCIO.with_in (path ^ ".expected") CCIO.read_all))
          with
          | Ok expected -> assert (Hcl_ast.equal ast expected)
          | Error _ -> assert false)
      | Error (#Hcl_ast.err as err) -> raise (Failure (Hcl_ast.show_err err)))

let make_fail_test path =
  Oth.test ~name:(Filename.basename path) (fun _ ->
      let contents = CCIO.with_in path CCIO.read_all in
      (* Failure tests can have multiple tests in the file which evaluate to
         same error. *)
      let tests =
        match CCString.split ~by:"\n---\n" contents with
        | [] -> assert false
        | tests -> tests
      in
      let expected = CCString.trim (CCIO.with_in (path ^ ".expected") CCIO.read_all) in
      CCList.iter
        (fun contents ->
          match Hcl_ast.of_string contents with
          | Ok ast -> raise (Failure (Hcl_ast.show ast))
          | Error (`Error (_, _, msg)) -> assert (CCString.equal expected msg))
        tests)

let parse_tests =
  let src_dir = Sys.getenv "SRC_DIR" in
  let files_dir = Filename.concat src_dir "files" in
  Sys.readdir (Filename.concat src_dir "files")
  |> CCArray.to_list
  |> CCList.sort CCString.compare
  |> CCList.filter (CCString.suffix ~suf:".hcl")
  |> CCList.flat_map (fun fname ->
         if CCString.suffix ~suf:"_bad.hcl" fname then
           [
             (* make_fail_test_expected (Filename.concat files_dir fname); *)
             make_fail_test (Filename.concat files_dir fname);
           ]
         else
           [
             (* make_success_test_expected (Filename.concat files_dir fname); *)
             make_success_test (Filename.concat files_dir fname);
           ])

let test = Oth.parallel parse_tests

let () =
  Random.self_init ();
  Oth.run test
