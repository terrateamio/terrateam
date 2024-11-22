let add_remove_pat = CCOption.get_exn_or "add_remove_pat" (Lua_pattern.of_string "^( +)([+~-])")
let add_remove_sub = Lua_pattern.rep_str "%2%1"

let transform plan_text =
  plan_text
  |> CCString.split_on_char '\n'
  |> CCSeq.of_list
  |> CCSeq.map (fun line ->
         match Lua_pattern.substitute ~s:line ~r:add_remove_sub add_remove_pat with
         | Some line -> line
         | None -> line)
  |> CCSeq.map (fun line ->
         if (not (CCString.is_empty line)) && line.[0] = '~' then CCString.set line 0 '!' else line)
  |> CCSeq.to_list
  |> CCString.concat "\n"
