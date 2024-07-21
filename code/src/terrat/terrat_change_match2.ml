module R = Terrat_base_repo_config_v1
module Dirspace_map = Terrat_data.Dirspace_map
module Dirspace_set = CCSet.Make (Terrat_dirspace)
module String_map = Terrat_data.String_map
module String_set = CCSet.Make (CCString)

type synthesize_config_err =
  [ `Bad_glob_err of string
  | `Depends_on_cycle_err of Terrat_dirspace.t list
  ]
[@@deriving show]

exception Synthesize_config_err of synthesize_config_err

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

module Dirspace_config = struct
  type t = {
    dirspace : Terrat_dirspace.t;
    file_pattern_matcher : string -> bool; [@opque]
    tags : Terrat_tag_set.t;
    when_modified : Terrat_base_repo_config_v1.When_modified.t;
  }
  [@@deriving show]
end

module Config = struct
  type t = {
    symlinks : string list CCTrie.String.t; [@opaque]
    dirspaces : Dirspace_config.t Dirspace_map.t;
    topology : Terrat_dirspace.t list Dirspace_map.t;
  }
  [@@deriving show]
end

let topology_of_dirspace_configs dirspaces =
  let module Wm = R.When_modified in
  let all_depends_on =
    CCList.filter_map
      (fun (dirspace, { Dirspace_config.when_modified = { Wm.depends_on; _ }; _ }) ->
        CCOption.map (fun depends_on -> (dirspace, depends_on)) depends_on)
      (Dirspace_map.to_list dirspaces)
  in
  let topology =
    Dirspace_map.fold
      (fun dirspace { Dirspace_config.tags; _ } acc ->
        match
          CCList.filter_map
            (fun (dirspace, depends_on) ->
              if Terrat_tag_query.match_ ~tag_set:tags ~dirspace depends_on then Some dirspace
              else None)
            all_depends_on
        with
        | [] -> acc
        | dependents -> (dirspace, dependents) :: acc)
      dirspaces
      []
  in
  match Tsort.sort topology with
  | Tsort.Sorted _ -> Dirspace_map.of_list topology
  | Tsort.ErrorCycle cycle -> raise (Synthesize_config_err (`Depends_on_cycle_err cycle))

let parse_glob globs =
  try Path_glob.Glob.parse (CCString.concat " or " (CCList.map (fun pat -> "<" ^ pat ^ ">") globs))
  with Path_glob.Ast.Parse_error _ ->
    (* Failed to parse, so now let's find the specific glob that failed *)
    CCList.iter
      (fun s ->
        try ignore (Path_glob.Glob.parse ("<" ^ s ^ ">"))
        with Path_glob.Ast.Parse_error _ -> raise (Synthesize_config_err (`Bad_glob_err s)))
      globs;
    (* Made it this far?  Something is wrong *)
    raise (Synthesize_config_err (`Bad_glob_err "Unknown"))

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
  let patterns_match fname = CCList.exists (CCFun.flip R.File_pattern.is_match fname) patterns in
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

let all_dir_match_patterns =
  (* All patterns start with "${DIR}" because we can do an optimization for file
     checking. *)
  CCList.for_all
    CCFun.(Terrat_base_repo_config_v1.File_pattern.file_pattern %> CCString.prefix ~pre:"${DIR}/")

let workspaces_of_workspaces_or_stacks ~tags dirname workspaces stacks =
  let module Ws = R.Dirs.Workspace in
  match (workspaces, stacks) with
  | _, st when not (R.String_map.is_empty st) ->
      R.String_map.mapi
        (fun k ws -> { ws with Ws.tags = [ "dir:" ^ dirname; "stack:" ^ k ] @ tags @ ws.Ws.tags })
        st
  | ws, _ when not (R.String_map.is_empty ws) ->
      R.String_map.mapi
        (fun k ws ->
          { ws with Ws.tags = [ "dir:" ^ dirname; "workspace:" ^ k ] @ tags @ ws.Ws.tags })
        ws
  | _, _ -> assert false

let update_file_patterns index module_paths dirname workspacename file_patterns =
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
  if String_set.mem dirname module_paths then []
  else
    let file_patterns =
      match String_map.find_opt dirname index.Index.deps with
      | Some mods ->
          CCList.filter_map
            (function
              | Index.Dep.Module path ->
                  Some (Filename.concat "${DIR}" (Filename.concat path "*.tf")))
            mods
          @ CCList.map R.File_pattern.file_pattern file_patterns
      | None -> CCList.map R.File_pattern.file_pattern file_patterns
    in
    CCList.map
      (fun pat ->
        CCResult.get_exn
          (R.File_pattern.make
             (process_relative_path
                (CCString.replace
                   ~sub:"${WORKSPACE}"
                   ~by:(escape_glob workspacename)
                   (CCString.replace ~sub ~by pat)))))
      file_patterns

let dirspace_configs_of_dir_config
    ~global_tags
    ~module_paths
    ~index
    ~default_when_modified
    dirname
    config =
  let module Dir = R.Dirs.Dir in
  let module Ws = R.Dirs.Workspace in
  let { Dir.create_and_select_workspace = _; stacks; tags; workspaces } = config in
  let workspaces =
    workspaces_of_workspaces_or_stacks ~tags:(global_tags @ tags) dirname workspaces stacks
  in
  CCList.map
    (fun (workspace, { Ws.tags; when_modified }) ->
      let module Wm = R.When_modified in
      let when_modified =
        {
          when_modified with
          Wm.file_patterns =
            update_file_patterns index module_paths dirname workspace when_modified.Wm.file_patterns;
        }
      in
      let file_pattern_matcher = compile_file_pattern_matcher when_modified.Wm.file_patterns in
      let tags = Terrat_tag_set.of_list tags in
      let dirspace = { Terrat_dirspace.dir = dirname; workspace } in
      { Dirspace_config.dirspace; file_pattern_matcher; tags; when_modified })
    (R.String_map.to_list workspaces)

let make_dir_map file_list =
  CCList.fold_left
    (fun acc fname ->
      let dirname = Filename.dirname fname in
      String_map.add_to_list dirname fname acc)
    String_map.empty
    file_list

let synthesize_config' ~ctx ~index ~file_list repo_config =
  let module Wm = R.When_modified in
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
  let { R.dirs; when_modified = default_when_modified; _ } = repo_config in
  let glob_dirs =
    dirs
    |> R.String_map.to_list
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
                   Some (process_relative_path (Filename.concat path mod_path)))
             values
           @ acc)
         index.Index.deps
         [])
  in
  let non_glob_dirspaces =
    dirs
    |> R.String_map.to_list
    |> CCList.filter (fun (d, _) -> not (CCString.contains d '*'))
    |> CCList.flat_map
         (CCFun.uncurry
            (dirspace_configs_of_dir_config
               ~global_tags
               ~module_paths
               ~index
               ~default_when_modified))
    |> CCList.map (fun ({ Dirspace_config.dirspace; _ } as ds) -> (dirspace, ds))
    |> Dirspace_map.of_list
  in
  let synthetic_dirspaces =
    file_list
    |> CCList.flat_map (fun fname ->
           match CCList.find_opt (fun (d, _) -> Path_glob.Glob.eval d fname) glob_dirs with
           | Some (_, config) ->
               let dir = Filename.dirname fname in
               dirspace_configs_of_dir_config
                 ~global_tags
                 ~module_paths
                 ~index
                 ~default_when_modified
                 dir
                 config
           | None -> [])
    |> CCList.map (fun ({ Dirspace_config.dirspace; _ } as ds) -> (dirspace, ds))
    |> Dirspace_map.of_list
  in
  let specified_dirspaces =
    Dirspace_map.union (fun _ v _ -> Some v) non_glob_dirspaces synthetic_dirspaces
  in
  let default_dir_config =
    R.Dirs.Dir.make
      ~workspaces:
        (R.String_map.of_list
           [ ("default", R.Dirs.Workspace.make ~when_modified:default_when_modified ()) ])
      ()
  in
  let remaining_dirspace_creator =
    if all_dir_match_patterns default_when_modified.Wm.file_patterns then fun (dirname, fnames) ->
      let dirspaces =
        dirspace_configs_of_dir_config
          ~global_tags
          ~module_paths
          ~index
          ~default_when_modified
          dirname
          default_dir_config
      in
      CCList.filter
        (fun { Dirspace_config.file_pattern_matcher; _ } ->
          CCList.exists file_pattern_matcher fnames)
        dirspaces
    else fun (dirname, fnames) ->
      dirspace_configs_of_dir_config
        ~global_tags
        ~module_paths
        ~index
        ~default_when_modified
        dirname
        default_dir_config
  in
  let specified_dirs =
    specified_dirspaces
    |> Dirspace_map.keys
    |> Iter.map (fun { Terrat_dirspace.dir; _ } -> dir)
    |> String_set.of_iter
  in
  let remaining_dirspaces =
    file_list
    |> CCList.filter (fun fname ->
           let dirname = Filename.dirname fname in
           not (String_set.mem dirname specified_dirs))
    |> make_dir_map
    |> String_map.to_list
    |> CCList.flat_map remaining_dirspace_creator
    |> CCList.map (fun ({ Dirspace_config.dirspace; _ } as ds) -> (dirspace, ds))
    |> Dirspace_map.of_list
  in
  let dirspaces =
    Dirspace_map.union (fun _ v _ -> Some v) specified_dirspaces remaining_dirspaces
  in
  let topology = topology_of_dirspace_configs dirspaces in
  { Config.symlinks; dirspaces; topology }

let synthesize_config ~ctx ~index ~file_list repo_config =
  try Ok (synthesize_config' ~ctx ~index ~file_list repo_config)
  with Synthesize_config_err err ->
    Error (err : synthesize_config_err :> [> synthesize_config_err ])

let files_of_diff = function
  | Terrat_change.Diff.Add { filename }
  | Terrat_change.Diff.Change { filename }
  | Terrat_change.Diff.Remove { filename } -> [ filename ]
  | Terrat_change.Diff.Move { filename; previous_filename } -> [ filename; previous_filename ]

let match_dir_map dirspaces dir_map =
  snd
    (String_map.fold
       (fun _ files ((dirspaces, matches) as acc) ->
         Dirspace_map.fold
           (fun dirspace
                ({ Dirspace_config.file_pattern_matcher; _ } as dirspace_config)
                ((dirspaces, matches) as acc) ->
             if CCList.exists file_pattern_matcher files then
               (Dirspace_map.remove dirspace dirspaces, dirspace_config :: matches)
             else acc)
           dirspaces
           acc)
       dir_map
       (dirspaces, []))

let rec collect_dependents topology dirspaces matches =
  CCList.flat_map
    (fun ({ Dirspace_config.dirspace; _ } as dirspace_config) ->
      dirspace_config
      :: collect_dependents
           topology
           dirspaces
           (CCList.map
              (CCFun.flip Dirspace_map.find dirspaces)
              (Dirspace_map.get_or ~default:[] dirspace topology)))
    matches

let group_independent_dirspaces topology dirspace_configs =
  CCList.rev
    (CCListLabels.fold_left
       ~f:(fun acc ({ Dirspace_config.dirspace; _ } as dirspace_config) ->
         match acc with
         | [] -> [ [ dirspace_config ] ]
         | dirspace_configs :: rest ->
             let dependents =
               Dirspace_set.of_list
                 (CCList.flat_map
                    (fun { Dirspace_config.dirspace; _ } ->
                      Dirspace_map.get_or ~default:[] dirspace topology)
                    dirspace_configs)
             in
             if Dirspace_set.mem dirspace dependents then [ dirspace_config ] :: acc
             else (dirspace_config :: dirspace_configs) :: rest)
       ~init:[]
       dirspace_configs)

let sort topology dirspaces matches =
  let topo =
    CCList.map
      (fun { Dirspace_config.dirspace; _ } ->
        (dirspace, Dirspace_map.get_or ~default:[] dirspace topology))
      matches
  in
  match Tsort.sort topo with
  | Tsort.Sorted sorted ->
      (* The topology as we defined it is (dependency -> dependents) which means our
         sort is going to come back in the opposite order we want to execute it.

         Additionally, we want to group things that can be executed in parallel together,
         so we need to group successive elements that are part of the same layer.

         What does it mean to be part of the same layer?  It means an element is
         not a dependent of any of the elements that proceded it in the list. *)
      sorted
      |> CCList.rev
      |> CCList.map (CCFun.flip Dirspace_map.find dirspaces)
      |> group_independent_dirspaces topology
  | Tsort.ErrorCycle _ ->
      (* This should be detected in the synthesize step *)
      assert false

let match_diff_list ?(force_matches = []) config diff_list =
  diff_list
  |> CCList.flat_map files_of_diff
  |> CCList.flat_map (map_symlink_file_path config.Config.symlinks)
  |> make_dir_map
  |> match_dir_map config.Config.dirspaces
  |> CCList.append force_matches
  |> collect_dependents config.Config.topology config.Config.dirspaces
  |> sort config.Config.topology config.Config.dirspaces

let of_dirspace config dirspace = Dirspace_map.get dirspace config.Config.dirspaces

let merge_with_dedup l1 l2 =
  let map_of_list l =
    Dirspace_map.of_list
      (CCList.map
         (fun ({ Dirspace_config.dirspace; _ } as dirspace_config) -> (dirspace, dirspace_config))
         l)
  in
  let m1 = map_of_list l1 in
  let m2 = map_of_list l2 in
  Iter.to_list (Dirspace_map.values (Dirspace_map.union (fun _ v _ -> Some v) m1 m2))

let match_tag_query ~tag_query { Dirspace_config.dirspace; tags; _ } =
  Terrat_tag_query.match_ ~tag_set:tags ~dirspace tag_query
