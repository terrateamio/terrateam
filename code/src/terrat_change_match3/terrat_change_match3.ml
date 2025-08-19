module R = Terrat_base_repo_config_v1
module String_map = Terrat_data.String_map
module Dirspace_map = Terrat_data.Dirspace_map
module Dirspace_set = Terrat_data.Dirspace_set

type synthesize_config_err =
  [ `Depends_on_cycle_err of Terrat_dirspace.t list
  | `Workspace_in_multiple_stacks_err of Terrat_dirspace.t
  ]
[@@deriving show]

exception Synthesize_config_err of synthesize_config_err

module Dirspace_config = struct
  type t = {
    dirspace : Terrat_dirspace.t;
    file_pattern_matcher : string -> bool; [@opque]
    lock_branch_target : Terrat_base_repo_config_v1.Dirs.Dir.Branch_target.t;
    stack_config : Terrat_base_repo_config_v1.Stacks.Stack.t;
    stack_name : string;
    tags : Terrat_tag_set.t;
    when_modified : Terrat_base_repo_config_v1.When_modified.t;
  }
  [@@deriving show]

  let to_yojson t =
    let module Ds = struct
      type t = {
        dir : string;
        workspace : string;
      }
      [@@deriving to_yojson]
    end in
    let module T = struct
      type t = {
        dirspace : Ds.t;
        tags : string list;
        when_modified : Terrat_base_repo_config_v1.When_modified.t;
      }
      [@@deriving to_yojson]
    end in
    T.to_yojson
      {
        T.dirspace =
          {
            Ds.dir = t.dirspace.Terrat_dirspace.dir;
            workspace = t.dirspace.Terrat_dirspace.workspace;
          };
        tags = Terrat_tag_set.to_list t.tags;
        when_modified = t.when_modified;
      }
end

module Config = struct
  type t = {
    symlinks : string list CCTrie.String.t; [@opaque]
    dirspaces : Dirspace_config.t Dirspace_map.t;
    topology : Terrat_dirspace.t list Dirspace_map.t;
  }
  [@@deriving show]

  let to_yojson t =
    let module T = struct
      type t = Dirspace_config.t list [@@deriving to_yojson]
    end in
    T.to_yojson (Iter.to_list (Dirspace_map.values t.dirspaces))
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
            (fun (working_dirspace, depends_on) ->
              let ctx = Terrat_tag_query.Ctx.make ~working_dirspace ~dirspace () in
              if Terrat_tag_query.match_ ~ctx ~tag_set:tags depends_on then Some working_dirspace
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

let build_symlinks =
  CCListLabels.fold_left
    ~f:(fun acc (src, dst) ->
      match CCTrie.String.find dst acc with
      | Some srcs -> CCTrie.String.add dst (src :: srcs) acc
      | None -> CCTrie.String.add dst [ src ] acc)
    ~init:CCTrie.String.empty

let compile_file_pattern_matcher file_patterns =
  let not_patterns, patterns = CCList.partition R.File_pattern.is_negate file_patterns in
  let patterns_match fname = CCList.exists (CCFun.flip R.File_pattern.is_match fname) patterns in
  let not_patterns_match fname =
    CCList.for_all (CCFun.flip R.File_pattern.is_match fname) not_patterns
  in
  fun fname -> patterns_match fname && not_patterns_match fname

let match_stacks dirspace tags stacks =
  CCList.filter
    (fun (_, { R.Stacks.Stack.tag_query; _ }) ->
      Terrat_tag_query.match_ ~ctx:(Terrat_tag_query.Ctx.make ~dirspace ()) ~tag_set:tags tag_query)
    stacks

let synthesize_config ~index repo_config =
  try
    let symlinks = build_symlinks index.R.Index.symlinks in
    let stacks = R.stacks repo_config in
    let stack_configs = Terrat_data.String_map.to_list stacks.R.Stacks.names in
    let no_default_stack = not (Terrat_data.String_map.mem "default" stacks.R.Stacks.names) in
    let dirspaces =
      repo_config
      |> R.dirs
      |> String_map.to_list
      |> CCList.flat_map (fun (dirname, config) ->
             let module D = R.Dirs.Dir in
             let module Ws = R.Dirs.Workspace in
             let module Wm = R.When_modified in
             CCList.flat_map
               (fun (workspace, workspace_config) ->
                 let dirspace = { Terrat_dirspace.dir = dirname; workspace } in
                 let tags = Terrat_tag_set.of_list workspace_config.Ws.tags in
                 (* Determine which stack the dirspace is part of.  In this
                    implementation, a dirspace can only be part of a single
                    stack.  If a dirspace does not match any stack AND there is
                    no [default] stack configured by the user, the dirspace
                    implicitly gets made part of the default stack.  In the
                    future, this dirspace should actually be filtered out rather
                    than fail. *)
                 let stack_name, stack_config =
                   match match_stacks dirspace tags stack_configs with
                   | [] when no_default_stack ->
                       ("default", R.Stacks.Stack.make ~tag_query:Terrat_tag_query.any ())
                   | [] -> raise (Failure "nyi")
                   | [ (stack_name, stack_config) ] -> (stack_name, stack_config)
                   | _ :: _ ->
                       raise (Synthesize_config_err (`Workspace_in_multiple_stacks_err dirspace))
                 in
                 let tags =
                   Terrat_tag_set.of_list (("stack_name:" ^ stack_name) :: workspace_config.Ws.tags)
                 in
                 (* If the dirspace is explicitly ignored via an empty
                    [file_patterns], do not even include it so that we don't
                    waste time trying to match against it. *)
                 match workspace_config.Ws.when_modified.Wm.file_patterns with
                 | [] -> []
                 | _ :: _ ->
                     [
                       ( dirspace,
                         {
                           Dirspace_config.dirspace;
                           file_pattern_matcher =
                             compile_file_pattern_matcher
                               workspace_config.Ws.when_modified.Wm.file_patterns;
                           lock_branch_target = config.D.lock_branch_target;
                           stack_config;
                           stack_name;
                           tags;
                           when_modified = workspace_config.Ws.when_modified;
                         } );
                     ])
               (String_map.to_list config.D.workspaces @ String_map.to_list config.D.stacks))
      |> Dirspace_map.of_list
    in
    let topology = topology_of_dirspace_configs dirspaces in
    Ok { Config.symlinks; dirspaces; topology }
  with Synthesize_config_err err ->
    Error (err : synthesize_config_err :> [> synthesize_config_err ])

let make_dir_map file_list =
  CCList.fold_left
    (fun acc fname ->
      let dirname = Filename.dirname fname in
      String_map.add_to_list dirname fname acc)
    String_map.empty
    file_list

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
                ((dirspaces, matches) as acc)
              ->
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
  let map_symlink_file_path symlinks fpath =
    match Iter.head (CCTrie.String.below fpath symlinks) with
    | Some (dst, srcs) when CCString.prefix ~pre:dst fpath ->
        CCList.map (fun src -> CCString.replace ~which:`Left ~sub:dst ~by:src fpath) srcs
    | Some _ | None -> [ fpath ]
  in
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
  let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
  Terrat_tag_query.match_ ~ctx ~tag_set:tags tag_query
