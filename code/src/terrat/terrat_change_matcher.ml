type t = {
  dirspaceflow : Terrat_change.Dirspaceflow.t;
  when_modified : Terrat_repo_config.When_modified.t;
}
[@@deriving show]

module Change_map = CCMap.Make (Terrat_change.Dirspace)

let find_workflow_idx tag_set workflows =
  CCOption.map
    fst
    (CCList.find_idx
       (fun workflow_entry ->
         let query =
           Terrat_tag_set.of_string workflow_entry.Terrat_repo_config.Workflow_entry.tag_query
         in
         Terrat_tag_set.match_ ~query tag_set)
       workflows)

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
      }
  | None -> default

let map_dirspace ?(tag_query = Terrat_tag_set.of_list []) repo_config dirspaces =
  let module Dirspace = Terrat_change.Dirspace in
  let module C = Terrat_repo_config in
  let dirs, default_when_modified, workflows =
    match repo_config with
    | { C.Version_1.dirs; when_modified; workflows; _ } ->
        ( CCOption.map_or
            ~default:Json_schema.String_map.empty
            (fun C.Version_1.Dirs.{ additional; _ } -> additional)
            dirs,
          CCOption.get_or ~default:(C.When_modified.make ()) when_modified,
          CCOption.get_or ~default:[] workflows )
  in
  let module Dir = Terrat_repo_config.Dir in
  let module When_modified = Terrat_repo_config.When_modified in
  dirspaces
  |> CCList.filter_map (fun Dirspace.{ dir; workspace } ->
         let dir_config =
           Json_schema.String_map.get_or
             ~default:
               Dir.
                 {
                   when_modified = None;
                   tags = Some [];
                   workspaces = None;
                   create_and_select_workspace = true;
                 }
             dir
             dirs
         in
         let when_modified =
           when_modified_of_when_modified_nullable
             default_when_modified
             dir_config.Dir.when_modified
         in
         let tags = ("dir:" ^ dir) :: CCOption.get_or ~default:[] dir_config.Dir.tags in
         (* Combine all tags into the workspace to make life a bit easier downstream *)
         let workspace_config =
           CCOption.get_or
             ~default:Dir.Workspaces.Additional.{ tags = [ "workspace:" ^ workspace ] @ tags }
             CCOption.(
               dir_config.Dir.workspaces
               >>= fun workspaces ->
               Json_schema.String_map.get workspace workspaces.Dir.Workspaces.additional
               >>= fun Dir.Workspaces.Additional.{ tags = workspace_tags } ->
               Some
                 Dir.Workspaces.Additional.
                   { tags = ("workspace:" ^ workspace) :: (tags @ workspace_tags) })
         in
         let tag_set = Terrat_tag_set.of_list workspace_config.Dir.Workspaces.Additional.tags in
         if Terrat_tag_set.match_ ~query:tag_query tag_set then
           Some
             {
               dirspaceflow =
                 Terrat_change.
                   {
                     Dirspaceflow.dirspace = Dirspace.{ dir; workspace };
                     workflow_idx = find_workflow_idx tag_set workflows;
                   };
               when_modified;
             }
         else None)

(* Given list of diffs we want to map them to their "directory configuration" or
   the global configuration if it does not match a specific directory.  To
   accomplish this we need to do a few transformations.  We need to figure out a
   few aspects:

   1. If the directory the file is in should be run.  To determine this find the
   directory in the dirs map, and if there is a match we test it against its
   file_pattern.  If the dir is not present, we test against the global.

   2. We determine if the change causes another directory to be included
   (file_pattern can reference any path). *)
let match_diff ?(tag_query = Terrat_tag_set.of_list []) repo_config diff =
  let module Diff = Terrat_change.Diff in
  let module C = Terrat_repo_config in
  let dirs, default_when_modified, workflows =
    match repo_config with
    | { C.Version_1.dirs; when_modified; workflows; _ } ->
        ( CCOption.map_or
            ~default:Json_schema.String_map.empty
            (fun C.Version_1.Dirs.{ additional; _ } -> additional)
            dirs,
          CCOption.get_or ~default:(C.When_modified.make ()) when_modified,
          CCOption.get_or ~default:[] workflows )
  in
  let module Dir = Terrat_repo_config.Dir in
  let module When_modified = Terrat_repo_config.When_modified in
  let module When_modified_null = Terrat_repo_config.When_modified_nullable in
  let matcher_of_file_pattern file_pattern =
    Path_glob.Glob.parse
      (CCString.concat " or " (CCList.map (fun pat -> "<" ^ pat ^ ">") file_pattern))
  in
  (* A filename matcher using the global [when_modified.file_patterns] value.
     Called "free" because this will be used to match files not associated with
     a directory in the [dirs] section. *)
  let free_fname_matcher =
    matcher_of_file_pattern default_when_modified.C.When_modified.file_patterns
  in
  (* Extract the file names from the diff. For the most part we do not care
     about what kind of changes they are just that the files are changed. *)
  let diff_filenames =
    CCList.flat_map
      (function
        | Diff.Add { filename } | Diff.Change { filename } | Diff.Remove { filename } ->
            [ filename ]
        | Diff.Move { filename; previous_filename } -> [ filename; previous_filename ])
      diff
  in
  (* Find all those directories in the [dirs] section that have a matching file
     in the diff.  We need to iterate the dirs and match to files because a
     directory config's [when_modified.file_patterns] can specify any path in it
     (for example the [dir1] config could specify a [file_patterns] like
     [dir1/*.tf, dir2/*.tf].  If we only used the [filename] to map to the [dir]
     if we had a change in [dir2/foo.tf] we would not map it to the [dir1]
     configuration. *)
  let matching_dirs =
    dirs
    |> Json_schema.String_map.to_list
    |> CCList.filter_map (fun (d, dir_config) ->
           CCOption.flat_map
             (fun when_modified ->
               match when_modified.When_modified_null.file_patterns with
               | Some [] | None ->
                   let diff_filenames_in_dir =
                     CCList.filter CCFun.(Filename.dirname %> CCString.equal d) diff_filenames
                   in
                   if CCList.exists (Path_glob.Glob.eval free_fname_matcher) diff_filenames_in_dir
                   then Some d
                   else None
               | Some file_patterns ->
                   let fname_matcher = matcher_of_file_pattern file_patterns in
                   if CCList.exists (Path_glob.Glob.eval fname_matcher) diff_filenames then Some d
                   else None)
             dir_config.Dir.when_modified)
  in
  let matches_when_changed fname =
    let dirname = Filename.dirname fname in
    match Json_schema.String_map.get dirname dirs with
    | Some dir_config ->
        let when_modified =
          when_modified_of_when_modified_nullable default_when_modified dir_config.Dir.when_modified
        in
        let fname_matcher = matcher_of_file_pattern when_modified.When_modified.file_patterns in
        Path_glob.Glob.eval fname_matcher fname
    | None -> Path_glob.Glob.eval free_fname_matcher fname
  in
  (* Iterate the diff and collect those files that match a file pattern. *)
  let dirspaces =
    diff
    |> CCList.flat_map (function
           | Diff.Add { filename } | Diff.Change { filename } | Diff.Remove { filename } ->
               if matches_when_changed filename then [ filename ] else []
           | Diff.Move { filename; previous_filename } ->
               (if matches_when_changed filename then [ filename ] else [])
               @ if matches_when_changed previous_filename then [ previous_filename ] else [])
    |> CCList.map Filename.dirname
    |> CCList.append matching_dirs
    |> CCList.sort_uniq ~cmp:CCString.compare
    |> CCList.flat_map (fun dir ->
           let dir_config =
             match Json_schema.String_map.get dir dirs with
             | Some dir_config -> dir_config
             | None -> Dir.(make ())
           in
           let workspaces =
             CCOption.map_or
               ~default:
                 (Json_schema.String_map.singleton
                    "default"
                    Dir.Workspaces.Additional.{ tags = [] })
               (fun { Dir.Workspaces.additional; _ } -> additional)
               dir_config.Dir.workspaces
           in
           CCList.map
             (fun workspace -> Terrat_change.Dirspace.{ dir; workspace })
             (Iter.to_list (Json_schema.String_map.keys workspaces)))
  in
  map_dirspace ~tag_query repo_config dirspaces

let merge_dedup l r =
  let of_list v =
    v
    |> CCList.map (fun ({ dirspaceflow = Terrat_change.{ Dirspaceflow.dirspace; _ }; _ } as t) ->
           (dirspace, t))
    |> Change_map.of_list
  in
  let l = of_list l in
  let r = of_list r in
  Change_map.union
    (fun _ _ v ->
      (* Always take the right list *)
      Some v)
    l
    r
  |> Change_map.values
  |> Iter.to_list

let dirspaceflow { dirspaceflow; _ } = dirspaceflow
