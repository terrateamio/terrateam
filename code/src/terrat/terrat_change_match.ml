module String_set = CCSet.Make (CCString)
module String_map = CCMap.Make (CCString)
module Dirspace_map = CCMap.Make (Terrat_change.Dirspace)

type t = {
  create_and_select_workspace : bool;
  dirspace : Terrat_change.Dirspace.t;
  tags : Terrat_tag_set.t;
  when_modified : Terrat_repo_config.When_modified.t;
}
[@@deriving show]

exception Bad_glob of string

let workspaces_or_stacks ~default ~dirname ~config_tags workspaces stacks =
  let module Ws = Terrat_repo_config.Workspaces in
  match (workspaces, stacks, default) with
  | None, Some st, _ ->
      Ws.
        {
          st with
          additional =
            Json_schema.String_map.mapi
              (fun k Ws.Additional.{ tags } ->
                Ws.Additional.
                  { tags = (("dir:" ^ dirname) :: ("stack:" ^ k) :: tags) @ config_tags })
              st.Ws.additional;
        }
  | Some ws, _, _ | None, None, ws ->
      Ws.
        {
          ws with
          additional =
            Json_schema.String_map.mapi
              (fun k Ws.Additional.{ tags } ->
                Ws.Additional.
                  { tags = (("dir:" ^ dirname) :: ("workspace:" ^ k) :: tags) @ config_tags })
              ws.Ws.additional;
        }

let parse_glob globs =
  try Path_glob.Glob.parse (CCString.concat " or " (CCList.map (fun pat -> "<" ^ pat ^ ">") globs))
  with Path_glob.Ast.Parse_error _ ->
    (* Failed to parse, so now let's find the specific glob that failed *)
    CCList.iter
      (fun s ->
        try ignore (Path_glob.Glob.parse ("<" ^ s ^ ">"))
        with Path_glob.Ast.Parse_error _ -> raise (Bad_glob s))
      globs;
    (* Made it this far?  Something is wrong *)
    raise (Bad_glob "Unknown")

let when_modified_of_when_modified_nullable default when_modified =
  let module Wm = Terrat_repo_config.When_modified in
  let module Wm_null = Terrat_repo_config.When_modified_nullable in
  match when_modified with
  | Some when_modified ->
      {
        Wm.file_patterns =
          CCOption.get_or ~default:default.Wm.file_patterns when_modified.Wm_null.file_patterns;
        autoplan = CCOption.get_or ~default:default.Wm.autoplan when_modified.Wm_null.autoplan;
        autoapply = CCOption.get_or ~default:default.Wm.autoapply when_modified.Wm_null.autoapply;
        autoplan_draft_pr =
          CCOption.get_or
            ~default:default.Wm.autoplan_draft_pr
            when_modified.Wm_null.autoplan_draft_pr;
      }
  | None -> default

module Dirs = struct
  module Dir = struct
    type t = {
      create_and_select_workspace : bool;
      file_pattern_matcher : string -> bool; [@opaque] [@to_yojson fun _ -> `String "<opaque>"]
      when_modified : Terrat_repo_config_when_modified.t;
      workspaces : Terrat_repo_config.Workspaces.t;
    }
    [@@deriving show, to_yojson]

    let default_workspaces =
      Terrat_repo_config.Workspaces.(
        make
          ~additional:(Json_schema.String_map.of_list [ ("default", Additional.make ~tags:[]) ])
          Json_schema.Empty_obj.t)

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
      let not_patterns, patterns = CCList.partition (CCString.prefix ~pre:"!") file_patterns in
      let not_patterns = CCList.map (CCString.drop 1) not_patterns in
      let short_circuit =
        CCList.map
          (fun pat ->
            match CCString.index_opt pat '*' with
            | Some idx -> CCString.sub pat 0 idx
            | None -> pat)
          (not_patterns @ file_patterns)
      in
      let not_patterns_glob =
        match not_patterns with
        | [] -> CCFun.const false
        | not_patterns -> Path_glob.Glob.eval (parse_glob not_patterns)
      in
      let patterns_glob =
        match patterns with
        | [] -> CCFun.const false
        | patterns -> Path_glob.Glob.eval (parse_glob patterns)
      in
      fun fname ->
        CCList.exists (fun pre -> CCString.prefix ~pre fname) short_circuit
        && patterns_glob fname
        && not (not_patterns_glob fname)

    let process_dot_dot dirname =
      (* We want to support relative paths in file_patterns, to some extent.  We
         only support [/../], and it must be proceeded by a static directory,
         not a pattern.  The [${DIR}] variable must be expanded as well.  For
         example, [foo/bar/../baz] will be turned into [foo/baz].  But
         [foo/**/../baz] will result in [foo/baz] as well, removing the
         pattern.

         To do this, we will split the string on the string [/../], then reverse
         it, this is because we do not want to apply the transformation to the
         tail element and the easiest way to pull it out is to flip the list.
         Then we cut off whatever is after the last [/], and then put the tail
         back on and reveres it and put the string back together. *)
      if CCString.mem ~sub:"/../" dirname then
        match CCList.rev (CCString.split ~by:"/../" dirname) with
        | [] -> dirname
        | tail :: rest ->
            let processed =
              CCList.map
                (fun fragement ->
                  match CCString.Split.right ~by:"/" fragement with
                  | Some (d, _drop) -> d
                  | None -> fragement)
                rest
            in
            CCString.concat "/" (CCList.rev (tail :: processed))
      else dirname

    let of_config_dir default_when_modified dirname config =
      let module Dir = Terrat_repo_config.Dir in
      let module Ws = Terrat_repo_config.Workspaces in
      let module Wm = Terrat_repo_config.When_modified in
      let config_tags = CCOption.get_or ~default:[] config.Dir.tags in
      (* With CDKTK enabled, users can specify workspaces or stacks (but not
         both).  So we synthesize a workspaces object from either of these,
         preferring workspaces if it is present.  We are going to consider
         workspaces and stacks the same and translate everything that we track
         into workspaces. *)
      let workspaces =
        workspaces_or_stacks
          ~default:default_workspaces
          ~dirname
          ~config_tags
          config.Dir.workspaces
          config.Dir.stacks
      in
      let when_modified =
        let wm =
          when_modified_of_when_modified_nullable default_when_modified config.Dir.when_modified
        in
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
        Wm.
          {
            wm with
            file_patterns =
              CCList.map
                (fun pat -> process_dot_dot (CCString.replace ~sub ~by pat))
                wm.Wm.file_patterns;
          }
      in
      let file_pattern_matcher =
        match when_modified.Wm.file_patterns with
        | [] -> CCFun.const false
        | file_patterns -> compile_file_pattern_matcher file_patterns
      in
      {
        create_and_select_workspace = config.Dir.create_and_select_workspace;
        file_pattern_matcher;
        when_modified;
        workspaces;
      }
  end

  type t_printer = (string * Dir.t) list [@@deriving show]

  let yojson_of_stringmap m =
    `Assoc (CCList.map (fun (k, v) -> (k, Dir.to_yojson v)) (Json_schema.String_map.to_list m))

  type t =
    (Dir.t Json_schema.String_map.t
    [@printer fun fmt v -> pp_t_printer fmt (Json_schema.String_map.to_list v)]
    [@to_yojson yojson_of_stringmap])
  [@@deriving show, to_yojson]
end

(* But a ${DIR} in front of the default when modified.  The when modified
   configuration in the repo config implicitly has this.  In
   {!synthesize_dir_config} we are making the dir configuration to match every
   file, so we need the default config to work as if it were written as a dir
   config.

   The rule is if then when_modified entry starts with globbing, then we
   actually want to put the '${DIR}' in front.  For example, [*.hcl] should map
   to [${DIR}/*.hcl].  If it starts with [**] then we want to remove that and
   replace it with [${DIR}] so that it does not match subdirs. *)
let update_default_when_modified_file_patterns
    (Terrat_repo_config.When_modified.{ file_patterns; _ } as wm) =
  {
    wm with
    Terrat_repo_config.When_modified.file_patterns =
      CCList.map
        (function
          | s when CCString.prefix ~pre:"**/" s -> "${DIR}/" ^ CCString.drop 3 s
          | s when CCString.prefix ~pre:"*" s -> "${DIR}/" ^ s
          | s -> s)
        file_patterns;
  }

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
  CCList.for_all (CCString.prefix ~pre:"${DIR}/")

(* Given a list of files and a repository configuration, create a directory
   configuration that matches every file with their specific configuration. *)
let synthesize_dir_config' ~file_list repo_config =
  let module C = Terrat_repo_config in
  let module Dir = Terrat_repo_config.Dir in
  let module Wm = Terrat_repo_config.When_modified in
  let dirs, default_when_modified =
    match repo_config with
    | { C.Version_1.dirs; when_modified; _ } ->
        ( CCOption.map_or
            ~default:Json_schema.String_map.empty
            (fun C.Version_1.Dirs.{ additional; _ } -> additional)
            dirs,
          update_default_when_modified_file_patterns
            (CCOption.get_or ~default:(C.When_modified.make ()) when_modified) )
  in
  let glob_dirs =
    dirs
    |> Json_schema.String_map.to_list
    (* We sort the dirs section by longest-first (in terms of number of
       characters).  The heuristic is that a longer directory specification is a
       more specific and thus, to be preferred in the search. *)
    |> CCList.sort (fun (d1, _) (d2, _) -> CCInt.compare (CCString.length d2) (CCString.length d1))
    (* Any dir with '*' is considered a glob, for example foo/bar/* *)
    |> CCList.filter (fun (d, _) -> CCString.contains d '*')
    |> CCList.map (fun (d, config) -> (parse_glob [ d ], config))
  in
  let non_glob_dirs =
    dirs
    |> Json_schema.String_map.filter (fun d _ -> not (CCString.contains d '*'))
    |> Json_schema.String_map.mapi (Dirs.Dir.of_config_dir default_when_modified)
  in
  let synthetic_dirs =
    file_list
    |> CCList.filter_map (fun fname ->
           let open CCOption.Infix in
           CCList.find_opt (fun (d, _) -> Path_glob.Glob.eval d fname) glob_dirs
           >>= fun (_, config) ->
           let dir = Filename.dirname fname in
           Some (dir, Dirs.Dir.of_config_dir default_when_modified dir config))
    |> Json_schema.String_map.of_list
  in
  (* Combine the globed ones and the non-globed ones for all dirs that were
     specified.  We then need to go over the file list and find all those files
     that correspond to directories that have not been listed and then construct
     the default configuration for them. *)
  let specified_dirs =
    Json_schema.String_map.union (fun _ v _ -> Some v) non_glob_dirs synthetic_dirs
  in
  let default_dir_config = Dir.make () in
  let remaining_dir_creator =
    if all_dir_match_patterns default_when_modified.Wm.file_patterns then fun dirname fnames acc ->
      (* For the remaining files, we want to construct a default configuration.  But
         it's possible that these directories would never match anything anyways, so
         we want to be careful.  If no files in the directory match the default
         [file_patterns], then we won't include it in the output.  This is because
         we could have a repository with a lot of directories in it that will never
         match anything, so rather than carry them around, just don't include them.
         It's a waste to try to match anything against them. *)
      let dir = Dirs.Dir.of_config_dir default_when_modified dirname default_dir_config in
      let file_pattern_matcher = dir.Dirs.Dir.file_pattern_matcher in
      if CCList.exists file_pattern_matcher fnames then (dirname, dir) :: acc else acc
    else fun dirname fnames acc ->
      let dir = Dirs.Dir.of_config_dir default_when_modified dirname default_dir_config in
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
  Json_schema.String_map.union (fun _ v _ -> Some v) specified_dirs remaining_dirs

let synthesize_dir_config ~file_list repo_config =
  try Ok (synthesize_dir_config' ~file_list repo_config) with Bad_glob s -> Error (`Bad_glob s)

let match_filename_in_dirs dirs fnames =
  (* Match a filename to any directories and remove those directories on match.
     We only need to match a directory once for any file, so there is no need to
     check it against future files. *)
  let module Ws = Terrat_repo_config.Workspaces in
  (* A fold always goes to the end of the list, however if we match a file to a
     directory, we don't have to check any more files.  So we use a local
     exception as a means of local control flow to exit the fold early. *)
  let module Break = struct
    exception R of (Dirs.Dir.t Json_schema.String_map.t * t list)
  end in
  Json_schema.String_map.fold
    (fun dirname
         Dirs.Dir.{ create_and_select_workspace; file_pattern_matcher; when_modified; workspaces }
         (dirs, mtchs) ->
      try
        let mtchs =
          CCList.fold_left
            (fun acc fname ->
              if file_pattern_matcher fname then
                raise
                  (Break.R
                     ( Json_schema.String_map.remove dirname dirs,
                       Json_schema.String_map.fold
                         (fun workspace Ws.Additional.{ tags } acc ->
                           let mtch =
                             {
                               create_and_select_workspace;
                               dirspace = Terrat_change.Dirspace.{ dir = dirname; workspace };
                               tags = Terrat_tag_set.of_list tags;
                               when_modified;
                             }
                           in
                           mtch :: acc)
                         (Ws.additional workspaces)
                         acc ))
              else acc)
            mtchs
            fnames
        in
        (dirs, mtchs)
      with Break.R acc -> acc)
    dirs
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
          if String_map.is_empty dirs then
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
  |> make_dir_map
  |> match_dir_map dirs
  |> CCList.map (fun ({ dirspace; _ } as mtch) -> (dirspace, mtch))
  |> Dirspace_map.of_list
  |> Dirspace_map.values
  |> Iter.to_list

let of_dirspace dirs (Terrat_change.Dirspace.{ dir; workspace } as dirspace) =
  let module Ws = Terrat_repo_config.Workspaces in
  let open CCOption.Infix in
  Json_schema.String_map.find_opt dir dirs
  >>= fun Dirs.Dir.{ create_and_select_workspace; when_modified; workspaces; _ } ->
  Json_schema.String_map.find_opt workspace (Ws.additional workspaces)
  >>= fun Ws.Additional.{ tags } ->
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
