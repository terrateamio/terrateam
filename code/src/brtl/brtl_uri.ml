let join_path a b =
  let strip_trailing s =
    if CCString.suffix ~suf:"/" s then CCString.sub s 0 (CCString.length s - 1) else s
  in
  match (a, b) with
  | "", b -> b
  | a, "" -> a
  | a, b ->
      let a = strip_trailing a in
      if CCString.prefix ~pre:"/" b then a ^ b else a ^ "/" ^ b

let merge_base ~base uri =
  Uri.with_query (Uri.with_path base (join_path (Uri.path base) (Uri.path uri))) (Uri.query uri)
