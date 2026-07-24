let concat_many root segments = List.fold_left Filename.concat root segments

let normalize_path path =
  let is_abs = String.length path > 0 && path.[0] = '/' in
  let parts = String.split_on_char '/' path in
  let rec process_parts acc = function
    | [] -> List.rev acc
    | "." :: rest | "" :: rest -> process_parts acc rest
    | ".." :: rest -> (
        match acc with
        | ".." :: _ -> process_parts (".." :: acc) rest
        | _ :: prev_acc -> process_parts prev_acc rest
        | [] -> if is_abs then process_parts [] rest else process_parts (".." :: acc) rest)
    | part :: rest -> process_parts (part :: acc) rest
  in
  let processed = process_parts [] parts in
  let res = String.concat "/" processed in
  if is_abs then "/" ^ res else if res = "" then "." else res

let has_no_parent_escape path =
  let n = normalize_path path in
  Filename.is_relative n && n <> ".." && not (String.length n >= 3 && String.sub n 0 3 = "../")

(* Split a normalized non-absolute path into segments. [.] becomes the empty list so both
   [relpath ~from:"." ~to_:"a/b"] and [relpath ~from:"a/b" ~to_:"a/b"] work without special cases. *)
let segments_of_normalized n = if n = "." then [] else String.split_on_char '/' n

let relpath ~from ~to_ =
  let nfrom = normalize_path from in
  let nto = normalize_path to_ in
  assert (Filename.is_relative nfrom && Filename.is_relative nto);
  let from_segs = segments_of_normalized nfrom in
  let to_segs = segments_of_normalized nto in
  let rec drop_common a b =
    match (a, b) with
    | ah :: at, bh :: bt when ah = bh -> drop_common at bt
    | _ -> (a, b)
  in
  let from_rem, to_rem = drop_common from_segs to_segs in
  let ups = List.map (fun _ -> "..") from_rem in
  let segments = ups @ to_rem in
  match segments with
  | [] -> "."
  | _ -> String.concat "/" segments

let rec mkdir_p path =
  if CCString.equal path "/" || CCString.equal path "." || CCString.equal path "" then ()
  else if Sys.file_exists path then ()
  else (
    mkdir_p (Filename.dirname path);
    (* An already-created directory is not an error: concurrent callers building overlapping trees
       would otherwise race between the [file_exists] test above and this [mkdir]. *)
    try Sys.mkdir path 0o755 with Sys_error _ -> ())

let write_file ~dir ~filepath content =
  let full = Filename.concat dir filepath in
  mkdir_p (Filename.dirname full);
  CCIO.with_out full (fun oc -> output_string oc content)
