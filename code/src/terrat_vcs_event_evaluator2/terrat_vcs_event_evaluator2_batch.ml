module Dsf = Terrat_change.Dirspaceflow
module We = Terrat_base_repo_config_v1.Workflows.Entry

module Run_params = struct
  type t = string option * Yojson.Safe.t option [@@deriving eq]
end

let run_params_of_dirspaceflow = function
  | { Dsf.workflow = Some { Dsf.Workflow.workflow = { We.environment; runs_on; _ }; _ }; _ } ->
      (environment, runs_on)
  | _ -> (None, None)

(* Group dirspaceflows by the parameters their run is performed with.  Dirspaceflows that do not
   agree on these cannot share a work manifest. *)
let group_by_run_params dirspaceflows =
  CCListLabels.fold_left
    ~f:(fun acc dsf ->
      CCList.Assoc.update
        ~eq:Run_params.equal
        ~f:(fun v -> Some (dsf :: CCOption.get_or ~default:[] v))
        (run_params_of_dirspaceflow dsf)
        acc)
    ~init:[]
    dirspaceflows

(* Pack dirspaceflows into groups such that no group holds two dirspaceflows in the same dir, first
   fit.  The number of groups is the largest number of workspaces in any one dir. *)
let partition_by_dir dirspaceflows =
  let rec update_first_match ~test ~update = function
    | [] -> None
    | x :: xs when test x -> Some (update x :: xs)
    | x :: xs ->
        let open CCOption.Infix in
        update_first_match ~test ~update xs >>= fun xs -> Some (x :: xs)
  in
  let partitions =
    CCList.fold_left
      (fun groups ({ Dsf.dirspace = { Terrat_dirspace.dir; _ }; _ } as dsf) ->
        match
          update_first_match
            ~test:CCFun.(Sln_map.String.mem dir %> not)
            ~update:(Sln_map.String.add dir dsf)
            groups
        with
        | Some groups -> groups
        | None -> Sln_map.String.singleton dir dsf :: groups)
      []
      dirspaceflows
  in
  CCList.map CCFun.(Sln_map.String.to_list %> CCList.map snd) partitions

(* Partitions dirspaceflows into batches, each of which becomes its own work manifest.  A batch
   satisfies, in this order:

     1. The environment and runs_on, so all environments, and any runs that get their own runs_on
        configuration, get their own work manifest.

     2. Overlapping workspaces.  If a dir has multiple workspaces that will run in it, each gets its
        own batch.  This ensures isolation between those directories.

     3. max_workspaces_per_batch, which caps how large a batch may get.

   The order of 1 and 2 matters.  Dir isolation only requires that no single batch hold two
   workspaces of the same dir, so it must be applied *within* a run params group.  Applying it first
   packs dirspaceflows of differing environments into the same partition, which grouping by run
   params then shatters into single-dirspace batches, and because chunking can only split a batch
   further, max_workspaces_per_batch becomes unreachable. *)
let partition_by_run_params ~max_workspaces_per_batch dirspaceflows =
  (* Sort up front so that the packing in [partition_by_dir], and the chunk boundaries below, follow
     from the content of [dirspaceflows] rather than the order they happen to arrive in.  This is
     what makes batches consistent between runs. *)
  let dirspaceflows =
    CCList.sort
      (fun l r -> Terrat_dirspace.compare (Dsf.to_dirspace l) (Dsf.to_dirspace r))
      dirspaceflows
  in
  (* The configuration is an integer with no minimum, and chunking by less than one is undefined. *)
  let max_workspaces_per_batch = CCInt.max 1 max_workspaces_per_batch in
  dirspaceflows
  |> group_by_run_params
  |> CCList.flat_map (fun (run_params, dirspaceflows) ->
      dirspaceflows
      |> partition_by_dir
      |> CCList.flat_map
           CCFun.(
             CCList.chunks max_workspaces_per_batch %> CCList.map (fun chunk -> (run_params, chunk))))
