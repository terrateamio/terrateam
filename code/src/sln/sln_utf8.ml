exception Malformed_utf8 of int

(* No fragment may be smaller than the widest UTF-8 codepoint, otherwise a single codepoint could
   not fit in a fragment at all and the split would have nowhere to land. *)
let min_max_bytes = 4

(* The fold decodes rather than inspecting bytes, so a cut can only ever land between codepoints:
   the positions it reports are codepoint starts by construction, and there is no continuation-byte
   arithmetic to get wrong. It also sees malformed input, which is why this can reject such input
   rather than propagate it -- Postgres rejects invalid UTF-8 in [jsonb] outright, and failing here
   names the offending byte offset instead of leaving the caller with a store error about a value it
   cannot locate.

   Only the cut positions come out of the fold; the fragments themselves are [sub]s over the
   original. Accumulating decoded codepoints into a buffer instead would copy the same bytes at
   decode speed rather than at memcpy speed, on values large enough that the difference is the whole
   reason this module exists. *)
let split ~max_bytes s =
  let max_bytes = max min_max_bytes max_bytes in
  let len = CCString.length s in
  let cuts, _ =
    Uutf.String.fold_utf_8
      (fun (cuts, start) pos -> function
        | `Malformed _ -> raise (Malformed_utf8 pos)
        | `Uchar c ->
            let next = pos + Uchar.utf_8_byte_length c in
            (* Cut before the codepoint that would overrun the bound, never after it. *)
            if next - start > max_bytes then (pos :: cuts, pos) else (cuts, start))
      ([], 0)
      s
  in
  let rec fragments acc = function
    | a :: (b :: _ as rest) -> fragments (CCString.sub s a (b - a) :: acc) rest
    | _ -> CCList.rev acc
  in
  (* An empty [s] needs no special case: its bounds are [0; 0], which yield one empty fragment. *)
  fragments [] (0 :: CCList.rev (len :: cuts))
