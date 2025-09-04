type err = [ `Missing_var_err of string ] [@@deriving show]

let pat = CCOption.get_exn_or "pat" @@ Lua_pattern.of_string "%$%b{}"

let rec apply' vars buf s start =
  match Lua_pattern.mtch ~start s pat with
  | Some mtch ->
      let mtch_start, mtch_end = Lua_pattern.Match.range mtch in
      if mtch_start = 0 || s.[mtch_start - 1] <> '$' then (
        let mtch_s = Lua_pattern.Match.to_string mtch in
        (* Cut off the "${" in the beginning at "}" in the end *)
        let name = CCString.sub mtch_s 2 (CCString.length mtch_s - 3) in
        Buffer.add_substring buf s start (mtch_start - start);
        match vars name with
        | Some v ->
            Buffer.add_string buf v;
            apply' vars buf s mtch_end
        | None -> Error (`Missing_var_err name))
      else (
        Buffer.add_substring buf s start (mtch_start - start - 1);
        Buffer.add_substring buf s mtch_start (mtch_end - mtch_start);
        apply' vars buf s mtch_end)
  | None ->
      Buffer.add_substring buf s start (CCString.length s - start);
      Ok ()

let apply vars s =
  let open CCResult.Infix in
  let buf = Buffer.create @@ CCString.length s in
  apply' vars buf s 0 >>= fun () -> Ok (Buffer.contents buf)
