open Core.Std

let print line = function
  | Some sline ->
    print_endline sline
  | None ->
    print_endline line

let rec exec_subst pat rep =
  match In_channel.input_line In_channel.stdin with
    | Some line -> begin
      print line (Lua_pattern.substitute ~s:line ~r:rep pat);
      exec_subst pat rep
    end
    | None ->
      ()

let () =
  let pat = Lua_pattern.of_string Sys.argv.(1) in
  let rep = Lua_pattern.rep_str Sys.argv.(2) in
  match pat with
    | Some pat ->
      exec_subst pat rep
    | _ ->
      exit 1
