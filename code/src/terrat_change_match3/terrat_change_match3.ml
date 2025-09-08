module R = Terrat_base_repo_config_v1
module String_map = Terrat_data.String_map
module String_set = Terrat_data.String_set
module Dirspace_map = Terrat_data.Dirspace_map
module Dirspace_set = Terrat_data.Dirspace_set

type synthesize_config_err =
  [ `Depends_on_cycle_err of Terrat_dirspace.t list
  | `Workspace_in_multiple_stacks_err of Terrat_dirspace.t
  | `Workspace_matches_no_stacks_err of Terrat_dirspace.t
  | `Stack_not_found_err of string
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

let match_dependency ~dependent ~dependency =
  let module Wm = R.When_modified in
  let module S = R.Stacks.Stack in
  let module Rules = R.Stacks.Rules in
  let { Dirspace_config.dirspace; tags; stack_name; _ } = dependent in
  let {
    Dirspace_config.dirspace = working_dirspace;
    when_modified = { Wm.depends_on; _ };
    stack_config = { S.rules = { Rules.modified_by; _ }; _ };
    _;
  } =
    dependency
  in
  CCList.mem ~eq:CCString.equal stack_name modified_by
  || CCOption.map_or
       ~default:false
       (fun depends_on ->
         let ctx = Terrat_tag_query.Ctx.make ~working_dirspace ~dirspace () in
         Terrat_tag_query.match_ ~ctx ~tag_set:tags depends_on)
       depends_on

let match_plan_after_dependency ~dependent ~dependency =
  let module Wm = R.When_modified in
  let module S = R.Stacks.Stack in
  let module Rules = R.Stacks.Rules in
  let { Dirspace_config.dirspace; tags; stack_name; _ } = dependent in
  let {
    Dirspace_config.dirspace = working_dirspace;
    when_modified = { Wm.depends_on; _ };
    stack_config = { S.rules = { Rules.plan_after; _ }; _ };
    _;
  } =
    dependency
  in
  CCList.mem ~eq:CCString.equal stack_name plan_after
  || CCOption.map_or
       ~default:false
       (fun depends_on ->
         let ctx = Terrat_tag_query.Ctx.make ~working_dirspace ~dirspace () in
         Terrat_tag_query.match_ ~ctx ~tag_set:tags depends_on)
       depends_on

(* We are actually going to build the topology in the reverse direction.  It
   should be (A -> B_list) A depends on the results of B_list.  But we're going
   to switch it such that all B's depend on A before they can run.  This is
   because:

   1. For cyclic dependency check, it doesn't matter the actual direction.

   2. We want to use this as a lookup such that we can take a match we have and
      look up all those that depend on it running first. *)
let topology_of_dirspace_configs dirspaces =
  let module Wm = R.When_modified in
  let module S = R.Stacks.Stack in
  let module Rules = R.Stacks.Rules in
  let dirspaces = Dirspace_map.to_list dirspaces in
  let topology =
    CCListLabels.fold_left
      ~f:(fun
          acc
          ( working_dirspace,
            {
              Dirspace_config.when_modified = { Wm.depends_on; _ };
              stack_config =
                { S.rules = { Rules.plan_after; apply_after; modified_by = _; auto_apply = _ }; _ };
              _;
            } )
        ->
        let all_stack_deps = plan_after @ apply_after in
        CCListLabels.fold_left
          ~f:(fun acc (dirspace, { Dirspace_config.tags; stack_name; _ }) ->
            let ctx = Terrat_tag_query.Ctx.make ~working_dirspace ~dirspace () in
            if
              CCOption.map_or ~default:false (Terrat_tag_query.match_ ~ctx ~tag_set:tags) depends_on
              || CCList.mem ~eq:CCString.equal stack_name all_stack_deps
            then
              (* This says adds [working_dirspace] in the list of dirspaces that
                 depend on [dirspace] being completed before they can run. *)
              Dirspace_map.add_to_list dirspace working_dirspace acc
            else acc)
          ~init:acc
          dirspaces)
      ~init:Dirspace_map.empty
      dirspaces
  in
  match Tsort.sort @@ Dirspace_map.to_list topology with
  | Tsort.Sorted _ -> topology
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
    (fun (_, config) ->
      match config with
      | { R.Stacks.Stack.type_ = R.Stacks.Type_.Stack tag_query; _ } ->
          Terrat_tag_query.match_
            ~ctx:(Terrat_tag_query.Ctx.make ~dirspace ())
            ~tag_set:tags
            tag_query
      | _ -> false)
    stacks

(* We want to support two operations around nested stacks.

   1. When a nested stack is defined we want to take its rules and variables
      section and recursively apply it to all stacks that it references.

   2. When a nested stack is referenced in a rule, we want to expand the rule
      out and incorporate it into the existing rule.

   The following configuration:

   stacks:
     names:
       databases:
         stacks:
           - database1
           - database2
         rules:
           modified_by:
             - base
       database1:
         tag_query: 'dir:database1'
       database2:
         tag_query: 'dir:database2'
       base:
         tag_query: 'dir:base'
       webservice:
         tag_query: 'dir:webservice'
         rules:
           modified_by:
             - databases

   Will be translated to:

   stacks:
     names:
       database1:
         tag_query: 'dir:database1'
         rules:
           modified_by:
             - base
       database2:
         tag_query: 'dir:database2'
         rules:
           modified_by:
             - base
       base:
         tag_query: 'dir:base'
       webservice:
         tag_query: 'dir:webservice'
         rules:
           modified_by:
             - database1
             - database2

   The one difference that makes this more than just a mechanical transformation
   is that the stackname [databases] is applied to the tags of [database1] and
   [database2]. *)

let stack_lookup name stacks =
  match String_map.find_opt name stacks with
  | Some stack -> stack
  | None -> raise (Synthesize_config_err (`Stack_not_found_err name))

let build_stack_lookup kv stacks =
  let module V1 = Terrat_base_repo_config_v1 in
  let module S = V1.Stacks in
  let rec collect_stacks path k =
    match stack_lookup k stacks with
    | { S.Stack.type_ = S.Type_.Nested ss; _ } ->
        CCList.flatten
        @@ CCList.filter_map
             (fun s ->
               if not (CCList.mem ~eq:CCString.equal s path) then
                 Some (collect_stacks (k :: path) s)
               else None)
             ss
    | { S.Stack.type_ = S.Type_.Stack _; _ } -> [ k ]
  in
  String_map.fold
    (fun k { S.Stack.type_; _ } acc ->
      match type_ with
      | S.Type_.Stack _ -> acc
      | S.Type_.Nested stack_refs ->
          CCListLabels.fold_left
            ~f:(fun acc s ->
              let k, v = kv k s in
              String_map.add_to_list k v acc)
            ~init:acc
            (CCList.flatten (CCList.map (fun s -> collect_stacks [ k ] s) stack_refs)))
    stacks
    String_map.empty

(* Lookup nested stack name -> stack names *)
let build_nested_to_stack_lookup stacks = build_stack_lookup (fun k v -> (k, v)) stacks

(* Lookup stack name -> nested stack names *)
let build_stack_to_nested_lookup stacks = build_stack_lookup (fun k v -> (v, k)) stacks

(* Build a lookup of a stack to which other stacks it modifies. *)
let build_modifies_lookup dirspace_configs =
  let module V1 = Terrat_base_repo_config_v1 in
  let module S = V1.Stacks in
  CCListLabels.fold_left
    ~f:(fun
        acc
        ({
           Dirspace_config.stack_name;
           stack_config = { S.Stack.rules = { S.Rules.modified_by; _ }; _ };
           _;
         } as dc)
      ->
      CCListLabels.fold_left ~f:(fun acc s -> String_map.add_to_list s dc acc) ~init:acc modified_by)
    ~init:String_map.empty
    dirspace_configs

let rec combine_rule accessor nested_lookup stacks vs =
  let module V1 = Terrat_base_repo_config_v1 in
  let module S = V1.Stacks in
  CCListLabels.fold_left
    ~f:(fun acc v ->
      match String_map.find_opt v nested_lookup with
      | Some ss ->
          CCListLabels.fold_left
            ~f:(fun acc s ->
              match String_map.find_opt s stacks with
              | Some config ->
                  let vs = accessor config in
                  combine_rule accessor nested_lookup stacks vs @ acc
              | None -> assert false)
            ~init:acc
            ss
      | None -> v :: acc)
    ~init:[]
    vs

let rec collect_deps ~path ~accessor name stacks =
  let module V1 = Terrat_base_repo_config_v1 in
  let module S = V1.Stacks in
  let stack = String_map.find name stacks in
  let { S.Stack.rules; _ } = stack in
  name
  :: CCList.flat_map
       (function
         | n when not (CCList.mem ~eq:CCString.equal n path) ->
             collect_deps ~path:(name :: path) ~accessor n stacks
         | _ -> [])
       (accessor rules)

(* Expand a config by any nested stacks its related to.  This expands it in two ways:

   1. For any nested stacks that reference us, we want to expand any rules they have into us.

   2. Any nested stacks that are referenced in a rule we want to expand to the
      concrete stack name.

   3. All transitive dependencies are expanded out.  So if A depends on B which
      depends on C, A will depend on B and C.

   We also want to do it in this order because we want any nested stacks to then
   be expanded out after they are added to the rules. *)
let expand_stack_config name config nested_to_stack_lookup stack_to_nested_lookup stacks =
  let module V1 = Terrat_base_repo_config_v1 in
  let module S = V1.Stacks in
  let module R = S.Rules in
  let { S.Stack.type_ = _; rules; variables } = config in
  let variables =
    CCListLabels.fold_left
      ~f:(fun acc s ->
        let { S.Stack.variables; _ } = stack_lookup s stacks in
        (* Merge variables but for any overlapping variables take the ones that
           already exist instead of overwriting them *)
        String_map.union (fun _ v _ -> Some v) acc variables)
      ~init:variables
      (String_map.get_or ~default:[] name stack_to_nested_lookup)
  in
  let { R.modified_by; plan_after; apply_after; auto_apply } =
    CCListLabels.fold_left
      ~f:(fun { R.modified_by; plan_after; apply_after; auto_apply } s ->
        let { S.Stack.rules; _ } = stack_lookup s stacks in
        {
          R.modified_by = modified_by @ rules.R.modified_by;
          plan_after = plan_after @ rules.R.plan_after;
          apply_after = apply_after @ rules.R.apply_after;
          auto_apply = CCOption.or_ ~else_:auto_apply rules.R.auto_apply;
        })
      ~init:rules
      (String_map.get_or ~default:[] name stack_to_nested_lookup)
  in
  let rules =
    {
      R.modified_by =
        String_set.to_list
        @@ String_set.of_list
        @@ CCList.flat_map (fun n ->
               collect_deps ~path:[] ~accessor:(fun { R.modified_by; _ } -> modified_by) n stacks)
        @@ CCList.flat_map
             (fun s -> String_map.get_or ~default:[ s ] s nested_to_stack_lookup)
             modified_by;
      plan_after =
        String_set.to_list
        @@ String_set.of_list
        @@ CCList.flat_map (fun n ->
               collect_deps ~path:[] ~accessor:(fun { R.plan_after; _ } -> plan_after) n stacks)
        @@ CCList.flat_map
             (fun s -> String_map.get_or ~default:[ s ] s nested_to_stack_lookup)
             plan_after;
      apply_after =
        String_set.to_list
        @@ String_set.of_list
        @@ CCList.flat_map (fun n ->
               collect_deps ~path:[] ~accessor:(fun { R.apply_after; _ } -> apply_after) n stacks)
        @@ CCList.flat_map
             (fun s -> String_map.get_or ~default:[ s ] s nested_to_stack_lookup)
             apply_after;
      auto_apply;
    }
  in
  { config with S.Stack.rules; variables }

let assert_all_stacks_exist stacks =
  let module V1 = Terrat_base_repo_config_v1 in
  let module S = V1.Stacks in
  String_map.iter
    (fun _ { S.Stack.type_; rules; variables = _ } ->
      let nested_stacks =
        match type_ with
        | S.Type_.Nested stacks -> stacks
        | S.Type_.Stack _ -> []
      in
      let { S.Rules.modified_by; plan_after; apply_after; auto_apply = _ } = rules in
      let all_stacks = nested_stacks @ modified_by @ plan_after @ apply_after in
      CCList.iter (fun s -> ignore (stack_lookup s stacks)) all_stacks)
    stacks

let synthesize_config ~index repo_config =
  try
    let symlinks = build_symlinks index.R.Index.symlinks in
    let stacks = R.stacks repo_config in
    assert_all_stacks_exist stacks.R.Stacks.names;
    (* Lookup up for a stack name to the stacks nested under it. *)
    let nested_to_stack_lookup = build_nested_to_stack_lookup stacks.R.Stacks.names in
    (* Lookup of a stack to any stacks that nest it. *)
    let stack_to_nested_lookup = build_stack_to_nested_lookup stacks.R.Stacks.names in
    let stack_configs =
      String_map.mapi
        (fun name config ->
          let module V1 = Terrat_base_repo_config_v1 in
          let module S = V1.Stacks in
          match config with
          | { S.Stack.type_ = S.Type_.Stack _; _ } ->
              expand_stack_config
                name
                config
                nested_to_stack_lookup
                stack_to_nested_lookup
                stacks.R.Stacks.names
          | { S.Stack.type_ = S.Type_.Nested _; _ } -> config)
        stacks.R.Stacks.names
    in
    let no_default_stack = not (String_map.mem "default" stack_configs) in
    let stack_configs = Terrat_data.String_map.to_list stack_configs in
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
                       ( "default",
                         R.Stacks.Stack.make ~type_:(R.Stacks.Type_.Stack Terrat_tag_query.any) ()
                       )
                   | [] -> raise (Synthesize_config_err (`Workspace_matches_no_stacks_err dirspace))
                   | [ (stack_name, stack_config) ] -> (stack_name, stack_config)
                   | _ :: _ ->
                       raise (Synthesize_config_err (`Workspace_in_multiple_stacks_err dirspace))
                 in
                 let tags =
                   Terrat_tag_set.of_list
                     (CCList.map
                        (fun n -> "stack_name:" ^ n)
                        (stack_name
                        :: String_map.get_or ~default:[] stack_name stack_to_nested_lookup)
                     @ workspace_config.Ws.tags)
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

(* [matches] are those dirspace configs that we have identified from the diff.
   [dirspaces] is all dirspaces in the configuration file.  [topology] maps a
   dirspace to every dirspace that depends on it.  From this we produce every
   dirspace that is modified or should be considered modified based on the
   "modified_by" configuration. *)
let rec collect_depends_on_dependents topology dirspaces matches =
  let module Wm = R.When_modified in
  let module S = R.Stacks.Stack in
  let module Rules = R.Stacks.Rules in
  CCList.flat_map
    (fun ({ Dirspace_config.dirspace; stack_name; _ } as dirspace_config) ->
      dirspace_config
      :: collect_depends_on_dependents
           topology
           dirspaces
           (CCList.filter_map
              (fun ds ->
                let open CCOption.Infix in
                Dirspace_map.get ds dirspaces
                >>= fun dependency ->
                if match_dependency ~dependent:dirspace_config ~dependency then Some dependency
                else None)
              (Dirspace_map.get_or ~default:[] dirspace topology)))
    matches

let rec collect_modified_by_dependents ~path modifies_lookup dirspaces matches =
  let module Wm = R.When_modified in
  let module S = R.Stacks.Stack in
  let module Rules = R.Stacks.Rules in
  CCList.flat_map
    (fun ({ Dirspace_config.dirspace; stack_name; _ } as dirspace_config) ->
      if not (CCList.mem ~eq:CCString.equal stack_name path) then
        dirspace_config
        :: collect_modified_by_dependents
             ~path:(stack_name :: path)
             modifies_lookup
             dirspaces
             (String_map.get_or ~default:[] stack_name modifies_lookup)
      else [])
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
      (fun ({ Dirspace_config.dirspace; _ } as dependent) ->
        ( dirspace,
          CCList.filter_map (fun ds ->
              let open CCOption.Infix in
              Dirspace_map.get ds dirspaces
              >>= fun dependency ->
              if match_plan_after_dependency ~dependent ~dependency then Some ds else None)
          @@ Dirspace_map.get_or ~default:[] dirspace topology ))
      matches
  in
  let match_set =
    Dirspace_set.of_list @@ CCList.map (fun { Dirspace_config.dirspace; _ } -> dirspace) matches
  in
  match Tsort.sort topo with
  | Tsort.Sorted sorted ->
      (* The topology as we defined it is (dependency -> dependents) which means our
         sort is going to come back in the opposite order we want to execute it.

         Additionally, we want to group things that can be executed in parallel together,
         so we need to group successive elements that are part of the same layer.

         What does it mean to be part of the same layer?  It means an element is
         not a dependent of any of the elements that proceded it in the list. *)
      let topo = Dirspace_map.of_list topo in
      sorted
      |> CCList.filter CCFun.(flip Dirspace_set.mem match_set)
      |> CCList.rev
      |> CCList.map (CCFun.flip Dirspace_map.find dirspaces)
      |> group_independent_dirspaces topo
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
  let modifies_lookup =
    build_modifies_lookup @@ Iter.to_list @@ Dirspace_map.values config.Config.dirspaces
  in
  diff_list
  |> CCList.flat_map files_of_diff
  |> CCList.flat_map (map_symlink_file_path config.Config.symlinks)
  |> make_dir_map
  |> match_dir_map config.Config.dirspaces
  |> CCList.append force_matches
  |> collect_depends_on_dependents config.Config.topology config.Config.dirspaces
  |> collect_modified_by_dependents ~path:[] modifies_lookup config.Config.dirspaces
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
