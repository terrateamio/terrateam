open Core.Std

let exec_mtch str pat =
  match Lua_pattern.mtch str pat with
    | Some m -> begin
      let (s, e) = Lua_pattern.Match.range m in
      let captures = Lua_pattern.Match.captures m in
      Printf.printf "Matched: (%d, %d)\n" s e;
      print_endline "Captures:";
      List.iter
        ~f:(fun c ->
          Printf.printf "(%d, %d) %s\n"
            (Lua_pattern.Capture.start c)
            (Lua_pattern.Capture.stop c)
            (Lua_pattern.Capture.to_string c))
        captures
    end
    | None ->
      print_endline "Did not match"

let () =
  Printf.printf "Needle: %s\nHaystack: %s\n" Sys.argv.(1) Sys.argv.(2);
  match Lua_pattern.of_string Sys.argv.(1) with
    | Some pat ->
      exec_mtch Sys.argv.(2) pat
    | None ->
      print_endline "Not a valid pattern"
