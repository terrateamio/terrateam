module Cmdline = struct
  module C = Cmdliner

  let follow_local_sources =
    let doc = "Follow modules that are local sources and their module dependencies" in
    C.Arg.(value & flag & info ~doc [ "follow-local-sources" ])

  let only_local_sources =
    let doc = "Output only local sources" in
    C.Arg.(value & flag & info ~doc [ "only-local-sources" ])

  let file_patterns =
    let doc =
      "File patterns to match.  This applies only to input paths and not followed local sources.  \
       Multiple allowed. Default *.tf"
    in
    C.Arg.(value & opt_all string [ "*.tf" ] & info ~doc [ "p"; "file-pattern" ])

  let paths =
    let doc = "Directories to process." in
    C.Arg.(non_empty & pos_all string [] & info ~docv:"PATH" ~doc [])

  let collect_cmd f =
    let doc = "Collect module dependencies" in
    let exits = C.Cmd.Exit.defaults in
    C.Cmd.v
      (C.Cmd.info "collect" ~doc ~exits)
      C.Term.(const f $ follow_local_sources $ only_local_sources $ file_patterns $ paths)
end

let default_tf_matcher = Path_glob.Glob.parse "<*.tf>"

module String_map = struct
  include CCMap.Make (CCString)

  let to_yojson f t = `Assoc (CCList.map (fun (k, v) -> (k, f v)) (to_list t))

  let of_yojson f = function
    | `Assoc obj -> (
        try
          Ok
            (CCListLabels.fold_left
               ~f:(fun acc (k, v) ->
                 match f v with
                 | Ok v -> add k v acc
                 | Error err -> failwith err)
               ~init:empty
               obj)
        with Failure err -> Error err)
    | _ -> Error "Expected object"
end

module Output = struct
  module Dep = struct
    type t = {
      paths : string list;
      failures : string String_map.t;
    }
    [@@deriving yojson]
  end

  type t = Dep.t String_map.t [@@deriving yojson]
end

let rec concat_path f1 f2 =
  if CCString.prefix ~pre:"./" f2 then concat_path f1 (CCString.drop 2 f2)
  else if CCString.prefix ~pre:"../" f2 then concat_path (Filename.dirname f1) (CCString.drop 3 f2)
  else Filename.concat f1 f2

let rec process_path follow_local_sources only_local_sources file_pattern_matcher path =
  let files =
    Sys.readdir path
    |> CCArray.to_list
    |> CCList.filter (Path_glob.Glob.eval file_pattern_matcher)
    |> CCList.map (Filename.concat path)
  in
  CCList.flat_map
    (fun path ->
      let contents = CCIO.with_in path CCIO.read_all in
      match Hcl_ast.of_string contents with
      | Ok ast ->
          CCList.flat_map
            (fun m ->
              (if
                 (only_local_sources && Opentofu_mods.Module.is_source_local_path m)
                 || not only_local_sources
               then [ Ok (Opentofu_mods.Module.source m) ]
               else [])
              @
              if follow_local_sources || Opentofu_mods.Module.is_source_local_path m then
                process_path
                  follow_local_sources
                  only_local_sources
                  default_tf_matcher
                  (concat_path (Filename.dirname path) (Opentofu_mods.Module.source m))
              else [])
            (Opentofu_mods.collect_modules ast)
      | Error (`Error (_, _, err)) -> [ Error (path, err) ])
    files

let collect follow_local_sources only_local_sources file_patterns paths =
  let file_patterns_matcher =
    Path_glob.Glob.parse
      (CCString.concat " or " (CCList.map (fun s -> "<" ^ s ^ ">") file_patterns))
  in
  let output =
    String_map.of_list
      (CCList.map
         (fun path ->
           ( path,
             CCListLabels.fold_left
               ~f:(fun acc -> function
                 | Ok m -> Output.Dep.{ acc with paths = m :: acc.paths }
                 | Error (fname, err) ->
                     Output.Dep.{ acc with failures = String_map.add fname err acc.failures })
               ~init:Output.Dep.{ paths = []; failures = String_map.empty }
               (process_path follow_local_sources only_local_sources file_patterns_matcher path) ))
         paths)
  in
  print_endline (Yojson.Safe.pretty_to_string (Output.to_yojson output))

let cmds = Cmdline.[ collect_cmd collect ]

let () =
  let info = Cmdliner.Cmd.info (Filename.basename Sys.argv.(0)) in
  exit @@ Cmdliner.Cmd.eval @@ Cmdliner.Cmd.group info cmds
