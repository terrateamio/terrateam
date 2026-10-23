let remove_dot_segments path =
  let rec go acc = function
    | [] -> List.rev acc
    | ("" | ".") :: rest -> go acc rest
    | ".." :: rest -> (
        match acc with [] -> go [] rest | _ :: tl -> go tl rest)
    | seg :: rest -> go (seg :: acc) rest
  in
  path |> String.split_on_char '/' |> go [] |> String.concat "/"

let normalise uri = uri |> Uri.path |> Uri.pct_decode |> remove_dot_segments
let resolve_local_file ~docroot ~uri = Filename.concat docroot (normalise uri)
