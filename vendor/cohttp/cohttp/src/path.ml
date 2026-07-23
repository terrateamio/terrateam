let resolve_local_file ~docroot ~uri =
  let path = Uri.(pct_decode (path (resolve "http" (of_string "/") uri))) in
  let rel_path =
    if String.length path > 0 then String.sub path 1 (String.length path - 1)
    else ""
  in
  Filename.concat docroot rel_path
