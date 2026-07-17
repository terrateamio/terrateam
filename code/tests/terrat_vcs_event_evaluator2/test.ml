(* Tests for how dirspaceflows are partitioned into batches, where each batch becomes its own work
   manifest.

   The invariants a batch must satisfy:

   1. All dirspaceflows in a batch agree on (environment, runs_on).

   2. No batch contains two dirspaceflows in the same dir.

   3. No batch is larger than max_workspaces_per_batch.

   And, as much as the above allows, batches should be as large as possible: a user setting
   max_workspaces_per_batch should get batches of that size. *)

module Batch = Terrat_vcs_event_evaluator2.Batch
module Dsf = Terrat_change.Dirspaceflow
module V1 = Terrat_base_repo_config_v1
module We = V1.Workflows.Entry

let dsf ?environment ?runs_on ~dir ~workspace () =
  {
    Dsf.dirspace = { Terrat_dirspace.dir; workspace };
    workflow =
      Some
        {
          Dsf.Workflow.idx = 0;
          workflow = We.make ?environment ~runs_on ~tag_query:V1.Tag_query.any ();
        };
    variables = None;
  }

let batch_sizes batches = batches |> CCList.map (fun (_, dsfs) -> CCList.length dsfs)

(* Batches sorted by size so assertions do not depend on batch ordering. *)
let sorted_batch_sizes batches = batches |> batch_sizes |> CCList.sort CCInt.compare

let dirs_of_batch (_, dsfs) =
  CCList.map (fun { Dsf.dirspace = { Terrat_dirspace.dir; _ }; _ } -> dir) dsfs

let dirspaces_of batches =
  batches
  |> CCList.flat_map (fun (_, dsfs) -> CCList.map Dsf.to_dirspace dsfs)
  |> CCList.sort Terrat_dirspace.compare

let show_sizes batches =
  "[" ^ CCString.concat "; " (CCList.map CCInt.to_string (batch_sizes batches)) ^ "]"

let fail_sizes name expected batches =
  failwith (Printf.sprintf "%s: expected %s, got %s" name expected (show_sizes batches))

(* The regression.  Two dirs, each with a prod and a dev workspace.  Dir isolation only requires
   that no single batch hold two workspaces of the same dir, which is satisfied by {A/prod, B/prod}
   and {A/dev, B/dev}.  Partitioning by dir before grouping by environment mixes environments into
   the same partition, which the environment grouping then shatters into single-dirspace batches,
   making max_workspaces_per_batch unreachable. *)
let test_batches_across_dirs_within_an_environment =
  Oth.test ~name:"partition: batches across dirs within an environment" (fun _ ->
      let dirspaceflows =
        [
          dsf ~environment:"prod" ~dir:"a" ~workspace:"prod" ();
          dsf ~environment:"dev" ~dir:"a" ~workspace:"dev" ();
          dsf ~environment:"prod" ~dir:"b" ~workspace:"prod" ();
          dsf ~environment:"dev" ~dir:"b" ~workspace:"dev" ();
        ]
      in
      let batches = Batch.partition_by_run_params ~max_workspaces_per_batch:50 dirspaceflows in
      match sorted_batch_sizes batches with
      | [ 2; 2 ] -> ()
      | _ -> fail_sizes "two dirs x two envs, max=50" "two batches of 2 ([2; 2])" batches)

(* max_workspaces_per_batch is an int with no minimum in the config schema, and CCList.chunks raises
   Invalid_argument for n < 1. *)
let test_max_workspaces_per_batch_of_zero =
  Oth.test ~name:"partition: max_workspaces_per_batch of zero does not raise" (fun _ ->
      let dirspaceflows =
        [ dsf ~dir:"a" ~workspace:"default" (); dsf ~dir:"b" ~workspace:"default" () ]
      in
      match Batch.partition_by_run_params ~max_workspaces_per_batch:0 dirspaceflows with
      | batches ->
          if CCList.length (dirspaces_of batches) <> 2 then failwith "max=0 dropped dirspaces"
      | exception Invalid_argument msg ->
          failwith (Printf.sprintf "max=0 raised Invalid_argument: %s" msg))

let test_environments_are_not_mixed =
  Oth.test ~name:"partition: a batch never mixes environments" (fun _ ->
      let dirspaceflows =
        CCList.flat_map
          (fun dir ->
            [
              dsf ~environment:"prod" ~dir ~workspace:"prod" ();
              dsf ~environment:"dev" ~dir ~workspace:"dev" ();
            ])
          [ "a"; "b"; "c"; "d" ]
      in
      let batches = Batch.partition_by_run_params ~max_workspaces_per_batch:50 dirspaceflows in
      CCList.iter
        (fun (_, dsfs) ->
          let envs =
            dsfs
            |> CCList.filter_map (fun { Dsf.workflow; _ } ->
                CCOption.map
                  (fun { Dsf.Workflow.workflow = { We.environment; _ }; _ } -> environment)
                  workflow)
            |> CCList.uniq ~eq:(CCOption.equal CCString.equal)
          in
          if CCList.length envs > 1 then failwith "a batch mixed environments")
        batches)

let test_runs_on_is_not_mixed =
  Oth.test ~name:"partition: a batch never mixes runs_on" (fun _ ->
      let dirspaceflows =
        CCList.flat_map
          (fun dir ->
            [
              dsf ~runs_on:(`String "big") ~dir ~workspace:"big" ();
              dsf ~runs_on:(`String "small") ~dir ~workspace:"small" ();
            ])
          [ "a"; "b"; "c"; "d" ]
      in
      let batches = Batch.partition_by_run_params ~max_workspaces_per_batch:50 dirspaceflows in
      CCList.iter
        (fun (_, dsfs) ->
          let runs_on =
            dsfs
            |> CCList.filter_map (fun { Dsf.workflow; _ } ->
                CCOption.map
                  (fun { Dsf.Workflow.workflow = { We.runs_on; _ }; _ } -> runs_on)
                  workflow)
            |> CCList.uniq ~eq:(CCOption.equal Yojson.Safe.equal)
          in
          if CCList.length runs_on > 1 then failwith "a batch mixed runs_on")
        batches)

let test_dirs_are_isolated_within_a_batch =
  Oth.test ~name:"partition: a batch never holds two workspaces of the same dir" (fun _ ->
      let dirspaceflows =
        CCList.flat_map
          (fun dir ->
            CCList.map
              (fun i -> dsf ~dir ~workspace:(Printf.sprintf "ws%d" i) ())
              (CCList.range 1 4))
          [ "a"; "b"; "c" ]
      in
      let batches = Batch.partition_by_run_params ~max_workspaces_per_batch:50 dirspaceflows in
      CCList.iter
        (fun batch ->
          let dirs = dirs_of_batch batch in
          if CCList.length (CCList.uniq ~eq:CCString.equal dirs) <> CCList.length dirs then
            failwith "a batch held two workspaces of the same dir")
        batches)

let test_chunks_at_max_workspaces_per_batch =
  Oth.test ~name:"partition: chunks at max_workspaces_per_batch" (fun _ ->
      let dirspaceflows =
        CCList.map
          (fun i -> dsf ~dir:(Printf.sprintf "dir%03d" i) ~workspace:"default" ())
          (CCList.range 1 100)
      in
      let batches = Batch.partition_by_run_params ~max_workspaces_per_batch:50 dirspaceflows in
      match sorted_batch_sizes batches with
      | [ 50; 50 ] -> ()
      | _ -> fail_sizes "100 distinct dirs, one env, max=50" "two batches of 50 ([50; 50])" batches)

(* Dir isolation wins here: every workspace shares a dir, so each must get its own batch no matter
   what max_workspaces_per_batch says.  This case is not fixable by ordering. *)
let test_single_dir_gets_one_workspace_per_batch =
  Oth.test ~name:"partition: all workspaces in one dir get a batch each" (fun _ ->
      let dirspaceflows =
        CCList.map
          (fun i -> dsf ~dir:"a" ~workspace:(Printf.sprintf "ws%02d" i) ())
          (CCList.range 1 10)
      in
      let batches = Batch.partition_by_run_params ~max_workspaces_per_batch:50 dirspaceflows in
      if sorted_batch_sizes batches <> CCList.replicate 10 1 then
        fail_sizes "10 workspaces in one dir, max=50" "ten batches of 1" batches)

let test_partition_is_deterministic =
  Oth.test ~name:"partition: input order does not change the batches" (fun _ ->
      let dirspaceflows =
        CCList.flat_map
          (fun dir ->
            [
              dsf ~environment:"prod" ~dir ~workspace:"prod" ();
              dsf ~environment:"dev" ~dir ~workspace:"dev" ();
            ])
          [ "a"; "b"; "c"; "d" ]
      in
      let batches_of dsfs =
        dsfs
        |> Batch.partition_by_run_params ~max_workspaces_per_batch:3
        |> CCList.map (fun (_, dsfs) ->
            dsfs |> CCList.map Dsf.to_dirspace |> CCList.sort Terrat_dirspace.compare)
        |> CCList.sort (CCList.compare Terrat_dirspace.compare)
      in
      let expected = batches_of dirspaceflows in
      let reversed = batches_of (CCList.rev dirspaceflows) in
      if expected <> reversed then failwith "reversing the input changed the batches")

let test_every_dirspace_appears_exactly_once =
  Oth.test ~name:"partition: every dirspace appears in exactly one batch" (fun _ ->
      let dirspaceflows =
        CCList.flat_map
          (fun dir ->
            CCList.map
              (fun i ->
                dsf
                  ~environment:(Printf.sprintf "env%d" (i mod 3))
                  ~dir
                  ~workspace:(Printf.sprintf "ws%d" i)
                  ())
              (CCList.range 1 5))
          [ "a"; "b"; "c" ]
      in
      let batches = Batch.partition_by_run_params ~max_workspaces_per_batch:4 dirspaceflows in
      let expected =
        dirspaceflows |> CCList.map Dsf.to_dirspace |> CCList.sort Terrat_dirspace.compare
      in
      if dirspaces_of batches <> expected then
        failwith "batches did not contain exactly the input dirspaces")

let test =
  Oth.parallel
    [
      test_batches_across_dirs_within_an_environment;
      test_max_workspaces_per_batch_of_zero;
      test_environments_are_not_mixed;
      test_runs_on_is_not_mixed;
      test_dirs_are_isolated_within_a_batch;
      test_chunks_at_max_workspaces_per_batch;
      test_single_dir_gets_one_workspace_per_batch;
      test_partition_is_deterministic;
      test_every_dirspace_appears_exactly_once;
    ]

let () =
  Random.self_init ();
  Oth.run test
