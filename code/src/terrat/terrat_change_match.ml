module String_set = CCSet.Make (CCString)
module String_map = CCMap.Make (CCString)
module Dirspace_map = CCMap.Make (Terrat_change.Dirspace)

type synthesize_dir_config_err = [ `Bad_glob of string ] [@@deriving show]

exception Synthesize_dir_config_err of synthesize_dir_config_err

type t = {
  create_and_select_workspace : bool;
  dirspace : Terrat_change.Dirspace.t;
  tags : Terrat_tag_set.t;
  when_modified : Terrat_base_repo_config_v1.When_modified.t;
}
[@@deriving show]

module Ctx = struct
  type t = {
    dest_branch : string;
    branch : string;
  }

  let make ~dest_branch ~branch () = { dest_branch; branch }
end

module Index = struct
  module Dep = struct
    type t = Module of string
  end

  type t = {
    deps : Dep.t list String_map.t;
    symlinks : (string * string) list;
  }

  let empty = { symlinks = []; deps = String_map.empty }
  let make ~symlinks deps = { symlinks; deps = String_map.of_list deps }
end

let parse_glob globs =
  try Path_glob.Glob.parse (CCString.concat " or " (CCList.map (fun pat -> "<" ^ pat ^ ">") globs))
  with Path_glob.Ast.Parse_error _ ->
    (* Failed to parse, so now let's find the specific glob that failed *)
    CCList.iter
      (fun s ->
        try ignore (Path_glob.Glob.parse ("<" ^ s ^ ">"))
        with Path_glob.Ast.Parse_error _ -> raise (Synthesize_dir_config_err (`Bad_glob s)))
      globs;
    (* Made it this far?  Something is wrong *)
    raise (Synthesize_dir_config_err (`Bad_glob "Unknown"))

module Dirs = struct
  module Workspace = struct
    type t = {
      file_pattern_matcher : string -> bool; [@opaque] [@to_yojson fun _ -> `String "<opaque>"]
      workspace : Terrat_base_repo_config_v1.Dirs.Workspace.t;
    }
    [@@deriving show, to_yojson]
  end

  module Dir = struct
    type t = {
      create_and_select_workspace : bool;
      workspaces : Workspace.t Terrat_base_repo_config_v1.String_map.t;
    }
    [@@deriving show, to_yojson]

    let default_workspaces when_modified =
      let module R = Terrat_base_repo_config_v1 in
      R.String_map.of_list [ ("default", R.Dirs.Workspace.make ~when_modified ()) ]

    let escape_glob s =
      let b = Buffer.create (CCString.length s) in
      CCString.iter
        (function
          | ('a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' | '-' | '.' | ' ' | '/') as c ->
              Buffer.add_char b c
          | c ->
              Buffer.add_char b '\\';
              Buffer.add_char b c)
        s;
      Buffer.contents b

    let compile_file_pattern_matcher file_patterns =
      (* Checking file globs can be expensive, but most file globs start with
         directory prefix.  So we can do a fairly inexpensive prefix check on
         the filename first and if anything in there matches we then test the
         more expensive dir globs.

         TODO: Map the prefix to the specific file pattern so we only check
         those file patterns that have a prefix match. *)
      let module R = Terrat_base_repo_config_v1 in
      let not_patterns, patterns = CCList.partition R.File_pattern.is_negate file_patterns in
      let patterns_str =
        CCList.map
          (fun pat ->
            CCString.drop
              (if R.File_pattern.is_negate pat then 1 else 0)
              (R.File_pattern.file_pattern pat))
          file_patterns
      in
      let short_circuit =
        CCList.map
          (fun pat ->
            match CCString.index_opt pat '*' with
            | Some idx -> CCString.sub pat 0 idx
            | None -> pat)
          patterns_str
      in
      let patterns_match fname =
        CCList.exists (CCFun.flip R.File_pattern.is_match fname) patterns
      in
      let not_patterns_match fname =
        CCList.for_all (CCFun.flip R.File_pattern.is_match fname) not_patterns
      in
      fun fname ->
        CCList.exists (fun pre -> CCString.prefix ~pre fname) short_circuit
        && patterns_match fname
        && not_patterns_match fname

    let process_dot = CCString.replace ~which:`All ~sub:"/./" ~by:"/"

    let rec process_dot_dot dirname =
      (* We want to support relative paths in file_patterns, to some extent.  We
         only support [/../], and it must be proceeded by a static directory,
         not a pattern.  The [${DIR}] variable must be expanded as well.  For
         example, [foo/bar/../baz] will be turned into [foo/baz].  But
         [foo/**/../baz] will result in [foo/baz] as well, removing the
         pattern.

         To do this, we recursively split it in [/../], then cut the end off the
         left portion and sew it back.  It's a little expensive in that it
         splits and join the string continuously, but it's an easy
         implementation. *)
      match CCString.Split.left ~by:"/../" dirname with
      | Some (l, r) -> (
          match CCString.Split.right ~by:"/" l with
          | Some (l', _) -> process_dot_dot (l' ^ "/" ^ r)
          | None -> process_dot_dot r)
      | None -> dirname

    let process_relative_path dirname = process_dot_dot (process_dot dirname)

    let workspaces_or_stacks
        ~global_tags
        ~default
        ~dirname
        ~config_tags
        ~index
        ~module_paths
        workspaces
        stacks =
      let module R = Terrat_base_repo_config_v1 in
      let module Ws = Terrat_base_repo_config_v1.Dirs.Workspace in
      let module Wm = R.When_modified in
      let update_file_patterns workspace wm =
        let sub, by =
          match dirname with
          | "." ->
              (* The [.] directory is special in that our directory listings do
                 not start with [./].  So if the directory is "." we assume we can
                 just chop off the [${DIR}/].  So [${DIR}/*.tf] becomes [*.tf]
                 instead of [./*.tf] *)
              ("${DIR}/", "")
          | dirname -> ("${DIR}", escape_glob dirname)
        in
        {
          wm with
          Wm.file_patterns =
            (if String_set.mem dirname module_paths then []
             else
               let file_patterns =
                 match String_map.find_opt dirname index.Index.deps with
                 | Some mods ->
                     CCList.filter_map
                       (function
                         | Index.Dep.Module path ->
                             Some (Filename.concat "${DIR}" (Filename.concat path "*.tf")))
                       mods
                     @ CCList.map R.File_pattern.file_pattern wm.Wm.file_patterns
                 | None -> CCList.map R.File_pattern.file_pattern wm.Wm.file_patterns
               in
               CCList.map
                 (fun pat ->
                   CCResult.get_exn
                     (R.File_pattern.make
                        (process_relative_path
                           (CCString.replace
                              ~sub:"${WORKSPACE}"
                              ~by:workspace
                              (CCString.replace ~sub ~by pat)))))
                 file_patterns);
        }
      in
      match (workspaces, stacks) with
      | _, st when not (R.String_map.is_empty st) ->
          R.String_map.mapi
            (fun k { Ws.tags; when_modified } ->
              {
                Ws.tags = (("dir:" ^ dirname) :: ("stack:" ^ k) :: tags) @ global_tags @ config_tags;
                when_modified = update_file_patterns k when_modified;
              })
            st
      | ws, _ when not (R.String_map.is_empty ws) ->
          R.String_map.mapi
            (fun k { Ws.tags; when_modified } ->
              {
                Ws.tags =
                  (("dir:" ^ dirname) :: ("workspace:" ^ k) :: tags) @ global_tags @ config_tags;
                when_modified = update_file_patterns k when_modified;
              })
            ws
      | _, _ ->
          R.String_map.mapi
            (fun k { Ws.tags; when_modified } ->
              {
                Ws.tags =
                  (("dir:" ^ dirname) :: ("workspace:" ^ k) :: tags) @ global_tags @ config_tags;
                when_modified = update_file_patterns k when_modified;
              })
            default

    let of_config_dir ~global_tags module_paths index default_when_modified dirname config =
      let module R = Terrat_base_repo_config_v1 in
      let module Dir = R.Dirs.Dir in
      let module Ws = R.Dirs.Workspace in
      let module Wm = R.When_modified in
      let config_tags = config.Dir.tags in
      (* With CDKTK enabled, users can specify workspaces or stacks (but not
         both).  So we synthesize a workspaces object from either of these,
         preferring workspaces if it is present.  We are going to consider
         workspaces and stacks the same and translate everything that we track
         into workspaces. *)
      let workspaces =
        workspaces_or_stacks
          ~global_tags
          ~default:(default_workspaces default_when_modified)
          ~dirname
          ~config_tags
          ~index
          ~module_paths
          config.Dir.workspaces
          config.Dir.stacks
      in
      {
        create_and_select_workspace = config.Dir.create_and_select_workspace;
        workspaces =
          R.String_map.map
            (fun ws ->
              {
                Workspace.file_pattern_matcher =
                  compile_file_pattern_matcher ws.Ws.when_modified.Wm.file_patterns;
                workspace = ws;
              })
            workspaces;
      }
  end

  let yojson_of_cctrie_string m = `String "opaque"

  type t = {
    symlinks : (string list CCTrie.String.t[@opaque] [@to_yojson yojson_of_cctrie_string]);
    dirs : Dir.t Terrat_base_repo_config_v1.String_map.t;
  }
  [@@deriving show, to_yojson]
end

let make_dir_map file_list =
  CCList.fold_left
    (fun acc fname ->
      let dirname = Filename.dirname fname in
      match String_map.find_opt dirname acc with
      | Some l -> String_map.add dirname (fname :: l) acc
      | None -> String_map.add dirname [ fname ] acc)
    String_map.empty
    file_list

let all_dir_match_patterns =
  (* All patterns start with "${DIR}" because we can do an optimization for file
     checking. *)
  CCList.for_all
    CCFun.(Terrat_base_repo_config_v1.File_pattern.file_pattern %> CCString.prefix ~pre:"${DIR}/")

let build_symlinks =
  CCListLabels.fold_left
    ~f:(fun acc (src, dst) ->
      match CCTrie.String.find dst acc with
      | Some srcs -> CCTrie.String.add dst (src :: srcs) acc
      | None -> CCTrie.String.add dst [ src ] acc)
    ~init:CCTrie.String.empty

let map_symlink_file_path symlinks fpath =
  match Iter.head (CCTrie.String.below fpath symlinks) with
  | Some (dst, srcs) when CCString.prefix ~pre:dst fpath ->
      CCList.map (fun src -> CCString.replace ~which:`Left ~sub:dst ~by:src fpath) srcs
  | Some _ | None -> [ fpath ]

let match_branch_tag branch_name accessor repo_config =
  let module V1 = Terrat_base_repo_config_v1 in
  let module Ct = Terrat_repo_config.Custom_tags in
  let module Ctb = Terrat_repo_config.Custom_tags_branch in
  let tags = repo_config.V1.tags in
  let branch_tags = V1.String_map.to_list (accessor tags) in
  CCList.find_map
    (function
      | bt, pat when V1.Pattern.is_match pat branch_name -> Some bt
      | _, _ -> None)
    branch_tags

let compute_branch_tag ctx repo_config =
  let module T = Terrat_base_repo_config_v1.Tags in
  match_branch_tag ctx.Ctx.branch (fun { T.branch; _ } -> branch) repo_config

let compute_dest_branch_tag ctx repo_config =
  let module T = Terrat_base_repo_config_v1.Tags in
  match_branch_tag ctx.Ctx.dest_branch (fun { T.dest_branch; _ } -> dest_branch) repo_config

(* Given a list of files and a repository configuration, create a directory
   configuration that matches every file with their specific configuration. *)
let synthesize_dir_config' ~ctx ~index ~file_list repo_config =
  let module C = Terrat_base_repo_config_v1 in
  let module Wm = C.When_modified in
  let symlinks = build_symlinks index.Index.symlinks in
  let file_list = CCList.flat_map (map_symlink_file_path symlinks) file_list in
  let branch_tags =
    match compute_branch_tag ctx repo_config with
    | Some branch -> [ "branch:" ^ branch ]
    | None -> []
  in
  let dest_branch_tags =
    match compute_dest_branch_tag ctx repo_config with
    | Some branch -> [ "dest_branch:" ^ branch ]
    | None -> []
  in
  let global_tags = branch_tags @ dest_branch_tags in
  let { C.dirs; when_modified = default_when_modified; _ } = repo_config in
  let glob_dirs =
    dirs
    |> C.String_map.to_list
    (* We sort the dirs section by longest-first (in terms of number of
       characters).  The heuristic is that a longer directory specification is a
       more specific and thus, to be preferred in the search. *)
    |> CCList.sort (fun (d1, _) (d2, _) -> CCInt.compare (CCString.length d2) (CCString.length d1))
    (* Any dir with '*' is considered a glob, for example foo/bar/* *)
    |> CCList.filter (fun (d, _) -> CCString.contains d '*')
    |> CCList.map (fun (d, config) -> (parse_glob [ d ], config))
  in
  let module_paths =
    String_set.of_list
      (String_map.fold
         (fun path values acc ->
           CCList.filter_map
             (function
               | Index.Dep.Module mod_path ->
                   Some (Dirs.Dir.process_relative_path (Filename.concat path mod_path)))
             values
           @ acc)
         index.Index.deps
         [])
  in
  let non_glob_dirs =
    dirs
    |> C.String_map.filter (fun d _ -> not (CCString.contains d '*'))
    |> C.String_map.mapi
         (Dirs.Dir.of_config_dir ~global_tags module_paths index default_when_modified)
  in
  let synthetic_dirs =
    file_list
    |> CCList.filter_map (fun fname ->
           let open CCOption.Infix in
           CCList.find_opt (fun (d, _) -> Path_glob.Glob.eval d fname) glob_dirs
           >>= fun (_, config) ->
           let dir = Filename.dirname fname in
           Some
             ( dir,
               Dirs.Dir.of_config_dir
                 ~global_tags
                 module_paths
                 index
                 default_when_modified
                 dir
                 config ))
    |> Json_schema.String_map.of_list
  in
  (* Combine the globed ones and the non-globed ones for all dirs that were
     specified.  We then need to go over the file list and find all those files
     that correspond to directories that have not been listed and then construct
     the default configuration for them. *)
  let specified_dirs =
    Json_schema.String_map.union (fun _ v _ -> Some v) non_glob_dirs synthetic_dirs
  in
  let default_dir_config =
    C.Dirs.Dir.make ~workspaces:(Dirs.Dir.default_workspaces default_when_modified) ()
  in
  let remaining_dir_creator =
    if all_dir_match_patterns default_when_modified.Wm.file_patterns then fun dirname fnames acc ->
      (* For the remaining files, we want to construct a default configuration.  But
         it's possible that these directories would never match anything anyways, so
         we want to be careful.  If no files in the directory match the default
         [file_patterns], then we won't include it in the output.  This is because
         we could have a repository with a lot of directories in it that will never
         match anything, so rather than carry them around, just don't include them.
         It's a waste to try to match anything against them. *)
      let dir =
        Dirs.Dir.of_config_dir
          ~global_tags
          module_paths
          index
          default_when_modified
          dirname
          default_dir_config
      in
      let file_pattern_matcher fname =
        C.String_map.exists
          (fun _ { Dirs.Workspace.file_pattern_matcher; _ } -> file_pattern_matcher fname)
          dir.Dirs.Dir.workspaces
      in
      if CCList.exists file_pattern_matcher fnames then (dirname, dir) :: acc else acc
    else fun dirname fnames acc ->
      let dir =
        Dirs.Dir.of_config_dir
          ~global_tags
          module_paths
          index
          default_when_modified
          dirname
          default_dir_config
      in
      (dirname, dir) :: acc
  in
  let remaining_dirs =
    file_list
    |> CCList.filter_map (fun fname ->
           let dirname = Filename.dirname fname in
           if not (Json_schema.String_map.mem dirname specified_dirs) then Some fname else None)
    |> make_dir_map
    |> CCFun.flip (String_map.fold remaining_dir_creator) []
    |> Json_schema.String_map.of_list
  in
  {
    Dirs.dirs = Json_schema.String_map.union (fun _ v _ -> Some v) specified_dirs remaining_dirs;
    symlinks;
  }

let synthesize_dir_config ~ctx ~index ~file_list repo_config =
  try Ok (synthesize_dir_config' ~ctx ~index ~file_list repo_config)
  with Synthesize_dir_config_err err ->
    Error (err : synthesize_dir_config_err :> [> synthesize_dir_config_err ])

let match_filename_in_dirs dirs fnames =
  (* Match a filename to any directories and remove those directories on match.
     We only need to match a directory once for any file, so there is no need to
     check it against future files. *)
  let module R = Terrat_base_repo_config_v1 in
  let module Ws = R.Dirs.Workspace in
  (* A fold always goes to the end of the list, however if we match a file to a
     directory, we don't have to check any more files.  So we use a local
     exception as a means of local control flow to exit the fold early. *)
  let module Break = struct
    exception R of (Dirs.t * t list)
  end in
  R.String_map.fold
    (fun dirname { Dirs.Dir.create_and_select_workspace; workspaces } (dirs, mtchs) ->
      let file_pattern_matcher fname =
        R.String_map.exists
          (fun _ { Dirs.Workspace.file_pattern_matcher; _ } -> file_pattern_matcher fname)
          workspaces
      in
      try
        let mtchs =
          CCList.fold_left
            (fun acc fname ->
              (* See if there are any matches *)
              if file_pattern_matcher fname then
                raise
                  (Break.R
                     ( { dirs with Dirs.dirs = R.String_map.remove dirname dirs.Dirs.dirs },
                       R.String_map.fold
                         (fun workspace
                              {
                                Dirs.Workspace.workspace = { Ws.tags; when_modified };
                                file_pattern_matcher;
                              }
                              acc ->
                           (* But only add the actual matches *)
                           if file_pattern_matcher fname then
                             let mtch =
                               {
                                 create_and_select_workspace;
                                 dirspace = Terrat_change.Dirspace.{ dir = dirname; workspace };
                                 tags = Terrat_tag_set.of_list tags;
                                 when_modified;
                               }
                             in
                             mtch :: acc
                           else acc)
                         workspaces
                         acc ))
              else acc)
            mtchs
            fnames
        in
        (dirs, mtchs)
      with Break.R acc -> acc)
    dirs.Dirs.dirs
    (dirs, [])

let files_of_diff = function
  | Terrat_change.Diff.Add { filename }
  | Terrat_change.Diff.Change { filename }
  | Terrat_change.Diff.Remove { filename } -> [ filename ]
  | Terrat_change.Diff.Move { filename; previous_filename } -> [ filename; previous_filename ]

let match_dir_map dirs dir_map =
  (* A fold has no way to exit early so we use an exception as control flow. *)
  let module Break = struct
    exception R of t list
  end in
  try
    let _, mtchs =
      String_map.fold
        (fun _ files (dirs, acc) ->
          if String_map.is_empty dirs.Dirs.dirs then
            (* If there are no more directories to match against, return early *)
            raise (Break.R acc)
          else
            let dirs, mtchs = match_filename_in_dirs dirs files in
            (dirs, mtchs @ acc))
        dir_map
        (dirs, [])
    in
    mtchs
  with Break.R mtchs -> mtchs

let match_diff_list dirs diff_list =
  diff_list
  |> CCList.flat_map files_of_diff
  |> CCList.flat_map (map_symlink_file_path dirs.Dirs.symlinks)
  |> make_dir_map
  |> match_dir_map dirs
  |> CCList.map (fun ({ dirspace; _ } as mtch) -> (dirspace, mtch))
  |> Dirspace_map.of_list
  |> Dirspace_map.values
  |> Iter.to_list
  |> CCList.return

let of_dirspace dirs (Terrat_change.Dirspace.{ dir; workspace } as dirspace) =
  let module R = Terrat_base_repo_config_v1 in
  let module Ws = R.Dirs.Workspace in
  let open CCOption.Infix in
  R.String_map.find_opt dir dirs.Dirs.dirs
  >>= fun { Dirs.Dir.create_and_select_workspace; workspaces; _ } ->
  R.String_map.find_opt workspace workspaces
  >>= fun { Dirs.Workspace.workspace = { Ws.tags; when_modified }; _ } ->
  Some { create_and_select_workspace; dirspace; tags = Terrat_tag_set.of_list tags; when_modified }

let merge_with_dedup l r =
  l
  |> CCList.map (fun ({ dirspace; _ } as mtch) -> (dirspace, mtch))
  |> Dirspace_map.of_list
  |> CCFun.flip
       (CCList.fold_left (fun m t ->
            Dirspace_map.update
              t.dirspace
              (function
                | Some _ as v -> v
                | None -> Some t)
              m))
       r
  |> Dirspace_map.values
  |> Iter.to_list

let match_tag_query ~tag_query { tags; dirspace; _ } =
  Terrat_tag_query.match_ ~tag_set:tags ~dirspace tag_query
