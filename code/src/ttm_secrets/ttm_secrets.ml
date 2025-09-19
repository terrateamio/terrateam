let src = Logs.Src.create "secrets"

module Logs = (val Logs.src_log src : Logs.LOG)

module Cli = struct
  module C = Cmdliner

  let in_place =
    let doc = "Mask secrets in place" in
    C.Arg.(value & flag & info [ "i"; "in-place" ] ~doc)

  let secrets =
    let doc =
      "File with a list of secrets.  Multi-line secrets are supported.  The format is: lines \
       starting with a '.' designate a new secret, everything after the '.' are the secret.  Lines \
       starting with '+' add a new line and the rest of that line to the previous secret.  And a \
       line starting with anything else is added as if it started with a '.'."
    in
    C.Arg.(required & opt (some file) None & info [ "s"; "secrets" ] ~doc)

  let unmask =
    let doc =
      "File with a list of values to not mask if part of a secret.  This is used if there is data \
       that is considered a secret but if it contains or overlaps with other strings, do not mask \
       it.  See the 'secrets' option for details on the file format."
    in
    C.Arg.(value & opt (some file) None & info [ "unmask" ] ~doc)

  let mask =
    let doc = "Replace a secret with this" in
    C.Arg.(value & opt string "***" & info [ "mask" ] ~doc)

  let file =
    let doc = "File to mask, required if an in-place mask" in
    C.Arg.(value & pos 0 (some file) None & info [] ~doc ~docv:"FILE")
end

module Mask = struct
  (* 100 KB *)
  let mask_min_chunk_size = 1024 * 100

  let load_secrets_format fname =
    CCIO.with_in
      fname
      CCFun.(
        CCIO.read_lines_iter
        %> Iter.fold
             (fun acc l ->
               match (CCString.take 1 l, acc) with
               | ".", acc -> CCString.drop 1 l :: acc
               | "+", s :: acc -> (s ^ "\n" ^ CCString.drop 1 l) :: acc
               | "+", [] -> [ CCString.drop 1 l ]
               | _, acc -> l :: acc)
             [])

  let overlaps s1 s2 buf pos len =
    let start = CCInt.max (pos - CCString.length s1) 0 in
    match CCString.find ~start ~sub:s1 (Bytes.unsafe_to_string buf) with
    | -1 -> false
    | idx ->
        (* We want to snap the range to inside the secret, if it is inside the secret.

           For start, we get the minimum of the [idx] to the end of the secret, then
           the maximum between that and pos.

           For end, we take the maximum of the end of the unmask and the beginning of the secret,
           and then the minimum of that and the end of the secret*)
        let s = CCInt.max pos (CCInt.min idx (pos + CCString.length s2)) in
        let e = CCInt.min (pos + CCString.length s2) (CCInt.max (idx + CCString.length s1) pos) in
        pos < e && s < pos + CCString.length s2

  let overlaps_unmask unmasks secret buf pos len =
    CCList.exists (fun um -> overlaps um secret buf pos len) unmasks

  let is_prefix ?(start = 0) ~pre s =
    CCString.is_sub ~sub:pre 0 s start ~sub_len:(CCString.length pre)

  let rec find_first_secret unmasks secrets buf pos len =
    if 0 < len then
      match
        CCList.find_opt
          (fun s ->
            CCString.length s <= len && is_prefix ~start:pos ~pre:s (Bytes.unsafe_to_string buf))
          secrets
      with
      | Some secret when not (overlaps_unmask unmasks secret buf pos len) -> Some (pos, secret)
      | Some _ | None -> find_first_secret unmasks secrets buf (pos + 1) (len - 1)
    else None

  let rec mask_bytes ?(pos = 0) secrets unmasks mask buf len fout =
    if 0 < len then (
      match find_first_secret unmasks secrets buf pos len with
      | None -> fout buf pos len
      | Some (idx, secret) ->
          fout buf pos (idx - pos);
          fout mask 0 (Bytes.length mask);
          mask_bytes
            ~pos:(idx + CCString.length secret)
            secrets
            unmasks
            mask
            buf
            (len - CCString.length secret - (idx - pos))
            fout)
    else ()

  let rec go secrets max_secret_len unmask mask buf pos fin fout =
    match fin buf pos (Bytes.length buf - pos) with
    | 0 when 0 < pos -> mask_bytes ~pos:0 secrets unmask mask buf pos fout
    | 0 -> ()
    | n when max_secret_len < n ->
        mask_bytes ~pos:0 secrets unmask mask buf (pos + (n - max_secret_len)) fout;
        BytesLabels.blit
          ~src:buf
          ~dst:buf
          ~src_pos:(pos + (n - max_secret_len))
          ~dst_pos:0
          ~len:max_secret_len;
        go secrets max_secret_len unmask mask buf max_secret_len fin fout
    | n ->
        mask_bytes ~pos:0 secrets unmask mask buf (pos + n) fout;
        go secrets max_secret_len unmask mask buf 0 fin fout

  let do_mask ~secrets ~unmask ~mask ~fin ~fout () =
    (* Secrets are sorted longest to shortest because that's the order we want to match them *)
    let secrets =
      CCList.sort (fun s1 s2 -> CCInt.compare (CCString.length s2) (CCString.length s1)) secrets
    in
    let max_secret_len = CCOption.map_or ~default:0 CCString.length @@ CCList.head_opt secrets in
    (* We must read at least our max secret length + a bit more, because we will
       keep that amount between reads in order to ensure we find secrets that
       cross between read chunks.  We multiple min secret len by 2 just such
       that if it is larger than our min chunk size we are at least reading good
       amounts of data per chunk read, so we can make progress. *)
    let buffer_size = CCInt.max mask_min_chunk_size (max_secret_len * 2) in
    let buf = Bytes.create buffer_size in
    go secrets max_secret_len unmask mask buf 0 fin fout

  let run in_place secrets unmask mask file () =
    let mask = Bytes.of_string mask in
    let secrets = load_secrets_format secrets in
    let unmask = CCOption.map_or ~default:[] load_secrets_format unmask in
    let wrap f =
      match file with
      | Some fname -> (
          let run fout = CCIO.with_in fname (fun fin -> f ~fin:(input fin) ~fout ()) in
          match in_place with
          | false -> run (output stdout)
          | true -> (
              let temp_file =
                Filename.temp_file ~temp_dir:(Filename.dirname fname) "secrets" "mask"
              in
              try
                CCIO.with_out temp_file (fun fout -> run (output fout));
                Sys.remove fname;
                Sys.rename temp_file fname
              with exn ->
                Sys.remove temp_file;
                raise exn))
      | None -> f ~fin:(input stdin) ~fout:(output stdout) ()
    in
    wrap (do_mask ~secrets ~unmask ~mask)

  let cmd logs =
    let module C = Cmdliner in
    let doc = "Mask secrets in a file" in
    let exits = C.Cmd.Exit.defaults in
    C.Cmd.v
      (C.Cmd.info "mask" ~doc ~exits)
      C.Term.(const run $ Cli.in_place $ Cli.secrets $ Cli.unmask $ Cli.mask $ Cli.file $ logs)
end

let cmd logs =
  let module C = Cmdliner in
  let doc = "Secrets management" in
  let info = Cmdliner.Cmd.info ~doc "secrets" in
  C.Cmd.group info [ Mask.cmd logs ]
