let () =
  match Hcl_ast.of_string (CCIO.read_all stdin) with
  | Ok ast -> print_endline (Hcl_ast.show ast)
  | Error err ->
      Printf.eprintf "%s\n" (Hcl_ast.show_err err);
      exit 1
