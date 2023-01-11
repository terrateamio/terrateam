module String_set = CCSet.Make (CCString)
module Dirspace_map = CCMap.Make (Terrat_change.Dirspace)

type t = {
  create_and_select_workspace : bool;
  dirspace : Terrat_change.Dirspace.t;
  tags : Terrat_tag_set.t;
  when_modified : Terrat_repo_config.When_modified.t;
}
[@@deriving show]

exception No_matching_dir of string
exception Bad_glob of string

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
      file_pattern_matcher : string -> bool; [@opaque]
      when_modified : Terrat_repo_config_when_modified.t;
      workspaces : Terrat_repo_config_dir.Workspaces.t;
    }
    [@@deriving show]

    let default_workspaces =
      Terrat_repo_config.Dir.Workspaces.(
        make
          ~additional:(Json_schema.String_map.of_list [ ("default", Additional.make ~tags:[]) ])
          Json_schema.Empty_obj.t)

    let of_config_dir default_when_modified dirname config =
      let module Dir = Terrat_repo_config.Dir in
      let module Ws = Terrat_repo_config.Dir.Workspaces in
      let module Wm = Terrat_repo_config.When_modified in
      let workspaces = CCOption.get_or ~default:default_workspaces config.Dir.workspaces in
      let config_tags = CCOption.get_or ~default:[] config.Dir.tags in
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
          | dirname -> ("${DIR}", dirname)
        in
        Wm.
          {
            wm with
            file_patterns =
              CCList.map (fun pat -> CCString.replace ~sub ~by pat) wm.Wm.file_patterns;
          }
      in
      let file_pattern_matcher =
        match when_modified.Wm.file_patterns with
        | [] -> CCFun.const false
        | file_patterns -> Path_glob.Glob.eval (parse_glob file_patterns)
      in
      {
        create_and_select_workspace = config.Dir.create_and_select_workspace;
        file_pattern_matcher;
        when_modified;
        workspaces =
          Ws.
            {
              workspaces with
              additional =
                Json_schema.String_map.mapi
                  (fun k Ws.Additional.{ tags } ->
                    Ws.Additional.
                      { tags = (("dir:" ^ dirname) :: ("workspace:" ^ k) :: tags) @ config_tags })
                  workspaces.Ws.additional;
            };
      }
  end

  type t_printer = (string * Dir.t) list [@@deriving show]

  type t =
    (Dir.t Json_schema.String_map.t
    [@printer fun fmt v -> pp_t_printer fmt (Json_schema.String_map.to_list v)])
  [@@deriving show]
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
  let remaining_dirs =
    file_list
    |> CCList.filter_map (fun fname ->
           let dirname = Filename.dirname fname in
           if not (Json_schema.String_map.mem dirname specified_dirs) then Some dirname else None)
    |> String_set.of_list
    |> CCFun.flip
         (String_set.fold (fun dirname acc ->
              (dirname, Dirs.Dir.of_config_dir default_when_modified dirname default_dir_config)
              :: acc))
         []
    |> Json_schema.String_map.of_list
  in
  Json_schema.String_map.union (fun _ v _ -> Some v) specified_dirs remaining_dirs

let synthesize_dir_config ~file_list repo_config =
  try Ok (synthesize_dir_config' ~file_list repo_config) with Bad_glob s -> Error (`Bad_glob s)

let match_filename_in_dirs dirs fname =
  let module Ws = Terrat_repo_config.Dir.Workspaces in
  Json_schema.String_map.fold
    (fun dirname
         Dirs.Dir.{ create_and_select_workspace; file_pattern_matcher; when_modified; workspaces }
         acc ->
      if file_pattern_matcher fname then
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
          acc
      else acc)
    dirs
    []

let match_diff dirs diff =
  match diff with
  | Terrat_change.Diff.Add { filename }
  | Terrat_change.Diff.Change { filename }
  | Terrat_change.Diff.Remove { filename } -> match_filename_in_dirs dirs filename
  | Terrat_change.Diff.Move { filename; previous_filename } ->
      match_filename_in_dirs dirs filename @ match_filename_in_dirs dirs previous_filename

let match_diff_list dirs diff_list =
  diff_list
  |> CCList.flat_map (match_diff dirs)
  |> CCList.map (fun ({ dirspace; _ } as mtch) -> (dirspace, mtch))
  |> Dirspace_map.of_list
  |> Dirspace_map.values
  |> Iter.to_list

let of_dirspace dirs (Terrat_change.Dirspace.{ dir; workspace } as dirspace) =
  let module Ws = Terrat_repo_config.Dir.Workspaces in
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

let match_tag_query ~tag_query { tags; _ } = Terrat_tag_set.match_ ~query:tag_query tags
