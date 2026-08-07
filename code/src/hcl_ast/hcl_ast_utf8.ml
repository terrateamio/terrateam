let sanitize s =
  (* Strip a leading UTF-8 BOM (Byte Order Mark) ([U+FEFF] = [EF BB BF]). hclsyntax accepts one
     BOM only at byte 0; any occurrence further in the file is rejected as
     "Invalid character". Removing it here lets the lexer treat ALL
     [U+FEFF] occurrences as errors, without a positional carve-out. *)
  let s =
    if CCString.length s >= 3 && s.[0] = '\xef' && s.[1] = '\xbb' && s.[2] = '\xbf' then
      CCString.sub s 3 (CCString.length s - 3)
    else s
  in
  let len = CCString.length s in
  let buf = Bytes.of_string s in
  let peek j = if j < len then Some (Bytes.unsafe_get buf j) else None in
  let repair_byte_if_invalid_utf8 i =
    let d = String.get_utf_8_uchar s i in
    if Uchar.utf_decode_is_valid d then i + Uchar.utf_decode_length d
    else (
      Bytes.set buf i '?';
      i + 1)
  in
  let i = ref 0 in
  let state = ref `Normal in
  while !i < len do
    match !state with
    | `Normal -> (
        match (Bytes.unsafe_get buf !i, peek (!i + 1)) with
        | '"', _ ->
            state := `String;
            incr i
        | '#', _ ->
            state := `Line_comment;
            incr i
        | '/', Some '/' ->
            state := `Line_comment;
            i := !i + 2
        | '/', Some '*' ->
            state := `Block_comment;
            i := !i + 2
        | '<', Some '<' ->
            (* [<<MARKER] or [<<-MARKER] heredoc introducer. Skip past the
               marker line so the body isn't treated as top-level code. *)
            let start = !i + 2 in
            let start = if peek start = Some '-' then start + 1 else start in
            let rec scan_marker k =
              match peek k with
              | Some c
                when (c >= 'A' && c <= 'Z')
                     || (c >= 'a' && c <= 'z')
                     || (c >= '0' && c <= '9')
                     || c = '_' -> scan_marker (k + 1)
              | _ -> k
            in
            let marker_end = scan_marker start in
            if marker_end = start then incr i (* bare [<<], not a heredoc *)
            else
              let marker = Bytes.sub_string buf start (marker_end - start) in
              let rec find_nl k =
                if k >= len || Bytes.unsafe_get buf k = '\n' then k else find_nl (k + 1)
              in
              let nl = find_nl marker_end in
              state := `Heredoc marker;
              i := if nl < len then nl + 1 else nl
        | _ -> incr i)
    | `Line_comment -> (
        match Bytes.unsafe_get buf !i with
        | '\n' ->
            state := `Normal;
            incr i
        | c when Char.code c >= 0x80 -> i := repair_byte_if_invalid_utf8 !i
        | _ -> incr i)
    | `Block_comment -> (
        match (Bytes.unsafe_get buf !i, peek (!i + 1)) with
        | '*', Some '/' ->
            state := `Normal;
            i := !i + 2
        | c, _ when Char.code c >= 0x80 -> i := repair_byte_if_invalid_utf8 !i
        | _ -> incr i)
    | `String -> (
        match Bytes.unsafe_get buf !i with
        | '\\' when !i + 1 < len -> i := !i + 2
        | '"' ->
            state := `Normal;
            incr i
        | _ -> incr i)
    | `Heredoc marker ->
        let rec find_nl k =
          if k >= len || Bytes.unsafe_get buf k = '\n' then k else find_nl (k + 1)
        in
        let line_end = find_nl !i in
        let line = Bytes.sub_string buf !i (line_end - !i) in
        if CCString.equal (CCString.trim line) marker then state := `Normal;
        i := if line_end < len then line_end + 1 else line_end
  done;
  Bytes.unsafe_to_string buf
