(* This configuration is used for tests of the dirs configuration *)
let dirs_config =
  CCResult.get_exn
    (Terrat_repo_config.Version_1.of_yojson
       (`Assoc
         [
           ( "when_modified",
             `Assoc
               [
                 ( "file_patterns",
                   `List [ `String "**/*.tf"; `String "**/*.tfvars"; `String "**/*.json" ] );
                 ("autoplan", `Bool false);
                 ("autoapply", `Bool true);
               ] );
           ( "dirs",
             `Assoc
               [
                 ( "iam",
                   `Assoc
                     [
                       ( "when_modified",
                         `Assoc
                           [
                             ("autoplan", `Bool false);
                             ("file_patterns", `List [ `String "iam/*.tf" ]);
                           ] );
                     ] );
                 ( "ebl",
                   `Assoc
                     [
                       ( "when_modified",
                         `Assoc
                           [
                             ("autoapply", `Bool true);
                             ("file_patterns", `List [ `String "ebl/*.tf"; `String "ebl_modules" ]);
                           ] );
                     ] );
                 ( "ec2",
                   `Assoc
                     [
                       ( "when_modified",
                         `Assoc
                           [
                             (* This actually has an error in that it does not
                                match files in the ec2 directory, this error is
                                on purpose used for testing. *)
                             ("file_patterns", `List [ `String "iam/*.tf" ]);
                           ] );
                     ] );
                 ("s3", `Assoc [ ("tags", `List [ `String "s3" ]) ]);
                 ("lambda", `Assoc [ ("when_modified", `Assoc [ ("autoplan", `Bool true) ]) ]);
                 ("module", `Assoc [ ("when_modified", `Assoc [ ("file_patterns", `List []) ]) ]);
                 ( "null_file_patterns",
                   `Assoc [ ("when_modified", `Assoc [ ("file_patterns", `Null) ]) ] );
               ] );
         ]))

(* This config makes the mistake of having a directory that matches everything *)
let bad_dirs_config =
  CCResult.get_exn
    (Terrat_repo_config.Version_1.of_yojson
       (`Assoc
         [
           ( "dirs",
             `Assoc
               [
                 ( "iam",
                   `Assoc
                     [
                       ("when_modified", `Assoc [ ("file_patterns", `List [ `String "iam/*.tf" ]) ]);
                     ] );
                 ( "ebl",
                   `Assoc
                     [
                       ( "when_modified",
                         `Assoc
                           [
                             ("file_patterns", `List [ `String "ebl/*.tf"; `String "ebl_modules" ]);
                           ] );
                     ] );
                 ( "ec2",
                   `Assoc
                     [
                       ( "when_modified",
                         `Assoc
                           [
                             (* This should only match changes in the root
                                directory, no subdirs *)
                             ("file_patterns", `List [ `String "*.tf" ]);
                           ] );
                     ] );
                 ( "s3",
                   `Assoc
                     [
                       ("when_modified", `Assoc [ ("file_patterns", `List [ `String "**/*.tf" ]) ]);
                     ] );
               ] );
         ]))

let test_simple =
  Oth.test ~name:"Test simple" (fun _ ->
      let repo_config = CCResult.get_exn (Terrat_repo_config.Version_1.of_yojson (`Assoc [])) in
      let diff = Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" } ] in
      let changes = Terrat_change_matcher.match_diff repo_config diff in
      assert (CCList.length changes = 1))

let test_workflow_idx =
  Oth.test ~name:"Test workflow idx" (fun _ ->
      let repo_config =
        CCResult.get_exn
          (Terrat_repo_config.Version_1.of_yojson
             (`Assoc
               [
                 ( "workflows",
                   `List
                     [
                       `Assoc
                         [
                           ("tag_query", `String "workspace:default");
                           ( "plan",
                             `List
                               [
                                 `Assoc
                                   [
                                     ("type", `String "run");
                                     ("cmd", `List [ `String "echo"; `String "hi" ]);
                                   ];
                               ] );
                         ];
                     ] );
               ]))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "ec/ec2.tf" } ] in
      let changes = Terrat_change_matcher.match_diff repo_config diff in
      assert (CCList.length changes = 1);
      let change = CCList.hd changes in
      let module Tcm = Terrat_change_matcher in
      let module Tc = Terrat_change in
      assert (change.Tcm.dirspaceflow.Tc.Dirspaceflow.workflow_idx = Some 0))

let test_workflow_idx_tag_in_dir =
  Oth.test
    ~name:"Test workflow idx tag in dir"
    ~desc:"Test workflow idx matches when tag is in dirs"
    (fun _ ->
      let repo_config =
        CCResult.get_exn
          (Terrat_repo_config.Version_1.of_yojson
             (`Assoc
               [
                 ( "workflows",
                   `List
                     [
                       `Assoc
                         [
                           ("tag_query", `String "ec2");
                           ( "plan",
                             `List
                               [
                                 `Assoc
                                   [
                                     ("type", `String "run");
                                     ("cmd", `List [ `String "echo"; `String "hi" ]);
                                   ];
                               ] );
                         ];
                     ] );
                 ("dirs", `Assoc [ ("ec2", `Assoc [ ("tags", `List [ `String "ec2" ]) ]) ]);
               ]))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" } ] in
      let changes = Terrat_change_matcher.match_diff repo_config diff in
      assert (CCList.length changes = 1);
      let change = CCList.hd changes in
      let module Tcm = Terrat_change_matcher in
      let module Tc = Terrat_change in
      assert (change.Tcm.dirspaceflow.Tc.Dirspaceflow.workflow_idx = Some 0))

let test_workflow_idx_multiple_dirs =
  Oth.test
    ~name:"Test workflow idx multiple dirs"
    ~desc:"Test workflow idx matches when tag is in dirs with multiple dirs changed"
    (fun _ ->
      let repo_config =
        CCResult.get_exn
          (Terrat_repo_config.Version_1.of_yojson
             (`Assoc
               [
                 ( "workflows",
                   `List
                     [
                       `Assoc
                         [
                           ("tag_query", `String "ec2");
                           ( "plan",
                             `List
                               [
                                 `Assoc
                                   [
                                     ("type", `String "run");
                                     ("cmd", `List [ `String "echo"; `String "hi" ]);
                                   ];
                               ] );
                         ];
                     ] );
                 ( "dirs",
                   `Assoc
                     [
                       ("ec2", `Assoc [ ("tags", `List [ `String "ec2" ]) ]);
                       ("s3", `Assoc [ ("tags", `List [ `String "s3" ]) ]);
                     ] );
               ]))
      in
      let diff =
        Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" }; Add { filename = "s3/s3.tf" } ]
      in
      let changes = Terrat_change_matcher.match_diff repo_config diff in
      assert (CCList.length changes = 2);
      let change = CCList.hd changes in
      let module Tcm = Terrat_change_matcher in
      let module Tc = Terrat_change in
      assert (change.Tcm.dirspaceflow.Tc.Dirspaceflow.workflow_idx = Some 0))

let test_workflow_override =
  Oth.test ~name:"Test overriding workflow for all" (fun _ ->
      let repo_config =
        CCResult.get_exn
          (Terrat_repo_config.Version_1.of_yojson
             (`Assoc
               [
                 ( "workflows",
                   `List
                     [
                       `Assoc
                         [
                           ("tag_query", `String "");
                           ( "plan",
                             `List
                               [
                                 `Assoc
                                   [
                                     ("type", `String "run");
                                     ("cmd", `List [ `String "echo"; `String "hi" ]);
                                   ];
                               ] );
                         ];
                     ] );
               ]))
      in
      let diff =
        Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" }; Add { filename = "s3/s3.tf" } ]
      in
      let changes = Terrat_change_matcher.match_diff repo_config diff in
      assert (CCList.length changes = 2);
      let module Tcm = Terrat_change_matcher in
      let module Tc = Terrat_change in
      CCList.iter
        (fun change -> assert (change.Tcm.dirspaceflow.Tc.Dirspaceflow.workflow_idx = Some 0))
        changes)

let test_dir_match =
  Oth.test ~name:"Test dir match" (fun _ ->
      let repo_config = CCResult.get_exn (Terrat_repo_config.Version_1.of_yojson (`Assoc [])) in
      let diff =
        Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" }; Add { filename = "s3/s3.tf" } ]
      in
      let changes =
        Terrat_change_matcher.match_diff
          ~tag_query:(Terrat_tag_set.of_list [ "dir:ec2" ])
          repo_config
          diff
      in
      assert (CCList.length changes = 1))

let test_dirspace_map =
  Oth.test ~name:"Test dirspace map" (fun _ ->
      let repo_config = CCResult.get_exn (Terrat_repo_config.Version_1.of_yojson (`Assoc [])) in
      let dirspaces =
        Terrat_change.Dirspace.
          [ { dir = "ec2"; workspace = "default" }; { dir = "s3"; workspace = "default" } ]
      in
      let changes =
        Terrat_change_matcher.map_dirspace
          ~tag_query:(Terrat_tag_set.of_list [ "dir:ec2" ])
          repo_config
          dirspaces
      in
      assert (CCList.length changes = 1))

let test_dir_file_pattern =
  Oth.test ~name:"Test dir file pattern" (fun _ ->
      let repo_config =
        CCResult.get_exn
          (Terrat_repo_config.Version_1.of_yojson
             (`Assoc
               [
                 ( "dirs",
                   `Assoc
                     [
                       ( "iam",
                         `Assoc
                           [
                             ( "when_modified",
                               `Assoc [ ("file_patterns", `List [ `String "ec2/*.tf" ]) ] );
                           ] );
                       ("s3", `Assoc [ ("tags", `List [ `String "s3" ]) ]);
                     ] );
               ]))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" } ] in
      let changes = Terrat_change_matcher.match_diff repo_config diff in
      assert (CCList.length changes = 2))

let test_dir_config_iam =
  Oth.test ~name:"Test Dir Config IAM" (fun _ ->
      let diff = Terrat_change.Diff.[ Add { filename = "iam/foo.tf" } ] in
      let changes = Terrat_change_matcher.match_diff dirs_config diff in
      (* We match the iam and ec2 dir *)
      assert (CCList.length changes = 2);
      CCList.iter
        (fun c ->
          let module Tcm = Terrat_change_matcher in
          let module Trcwm = Terrat_repo_config.When_modified in
          let module Tcds = Terrat_change.Dirspaceflow in
          let module Ds = Terrat_change.Dirspace in
          match c.Tcm.dirspaceflow.Tcds.dirspace.Ds.dir with
          | "ec2" ->
              assert (not c.Tcm.when_modified.Trcwm.autoplan);
              assert c.Tcm.when_modified.Trcwm.autoapply
          | "iam" ->
              assert (not c.Tcm.when_modified.Trcwm.autoplan);
              assert c.Tcm.when_modified.Trcwm.autoapply
          | _ -> assert false)
        changes)

let test_dir_config_ebl =
  Oth.test ~name:"Test Dir Config ebl" (fun _ ->
      let diff = Terrat_change.Diff.[ Add { filename = "ebl/foo.tf" } ] in
      let changes = Terrat_change_matcher.match_diff dirs_config diff in
      assert (CCList.length changes = 1);
      CCList.iter
        (fun c ->
          let module Tcm = Terrat_change_matcher in
          let module Trcwm = Terrat_repo_config.When_modified in
          let module Tcds = Terrat_change.Dirspaceflow in
          let module Ds = Terrat_change.Dirspace in
          match c.Tcm.dirspaceflow.Tcds.dirspace.Ds.dir with
          | "ebl" ->
              assert (not c.Tcm.when_modified.Trcwm.autoplan);
              assert c.Tcm.when_modified.Trcwm.autoapply
          | _ -> assert false)
        changes)

let test_dir_config_ebl_modules =
  Oth.test ~name:"Test Dir Config ebl modules" (fun _ ->
      let diff = Terrat_change.Diff.[ Add { filename = "ebl_modules" } ] in
      let changes = Terrat_change_matcher.match_diff dirs_config diff in
      assert (CCList.length changes = 1);
      CCList.iter
        (fun c ->
          let module Tcm = Terrat_change_matcher in
          let module Trcwm = Terrat_repo_config.When_modified in
          let module Tcds = Terrat_change.Dirspaceflow in
          let module Ds = Terrat_change.Dirspace in
          match c.Tcm.dirspaceflow.Tcds.dirspace.Ds.dir with
          | "ebl" ->
              assert (not c.Tcm.when_modified.Trcwm.autoplan);
              assert c.Tcm.when_modified.Trcwm.autoapply
          | _ -> assert false)
        changes)

let test_dir_config_ebl_and_modules =
  Oth.test ~name:"Test Dir Config ebl and modules" (fun _ ->
      let diff =
        Terrat_change.Diff.[ Add { filename = "ebl_modules" }; Add { filename = "ebl/foo.tf" } ]
      in
      let changes = Terrat_change_matcher.match_diff dirs_config diff in
      assert (CCList.length changes = 1);
      CCList.iter
        (fun c ->
          let module Tcm = Terrat_change_matcher in
          let module Trcwm = Terrat_repo_config.When_modified in
          let module Tcds = Terrat_change.Dirspaceflow in
          let module Ds = Terrat_change.Dirspace in
          match c.Tcm.dirspaceflow.Tcds.dirspace.Ds.dir with
          | "ebl" ->
              assert (not c.Tcm.when_modified.Trcwm.autoplan);
              assert c.Tcm.when_modified.Trcwm.autoapply
          | _ -> assert false)
        changes)

let test_dir_config_s3 =
  Oth.test ~name:"Test Dir Config s3" (fun _ ->
      let diff = Terrat_change.Diff.[ Add { filename = "s3/foo.tf" } ] in
      let changes = Terrat_change_matcher.match_diff dirs_config diff in
      assert (CCList.length changes = 1);
      CCList.iter
        (fun c ->
          let module Tcm = Terrat_change_matcher in
          let module Trcwm = Terrat_repo_config.When_modified in
          let module Tcds = Terrat_change.Dirspaceflow in
          let module Ds = Terrat_change.Dirspace in
          match c.Tcm.dirspaceflow.Tcds.dirspace.Ds.dir with
          | "s3" ->
              assert (not c.Tcm.when_modified.Trcwm.autoplan);
              assert c.Tcm.when_modified.Trcwm.autoapply
          | _ -> assert false)
        changes)

let test_dir_config_lambda_json =
  Oth.test ~name:"Test Dir Config lambda JSON" (fun _ ->
      let diff = Terrat_change.Diff.[ Add { filename = "lambda/foo.json" } ] in
      let changes = Terrat_change_matcher.match_diff dirs_config diff in
      assert (CCList.length changes = 1);
      CCList.iter
        (fun c ->
          let module Tcm = Terrat_change_matcher in
          let module Trcwm = Terrat_repo_config.When_modified in
          let module Tcds = Terrat_change.Dirspaceflow in
          let module Ds = Terrat_change.Dirspace in
          match c.Tcm.dirspaceflow.Tcds.dirspace.Ds.dir with
          | "lambda" ->
              assert c.Tcm.when_modified.Trcwm.autoplan;
              assert c.Tcm.when_modified.Trcwm.autoapply
          | _ -> assert false)
        changes)

let test_dir_config_module =
  Oth.test ~name:"Test Dir Config module" (fun _ ->
      let diff = Terrat_change.Diff.[ Add { filename = "module/foo.tf" } ] in
      let changes = Terrat_change_matcher.match_diff dirs_config diff in
      assert (CCList.length changes = 0))

let test_dir_config_null_file_patterns =
  Oth.test ~name:"Test Dir Config null_file_patterns" (fun _ ->
      let diff = Terrat_change.Diff.[ Add { filename = "null_file_patterns/foo.tf" } ] in
      let changes = Terrat_change_matcher.match_diff dirs_config diff in
      assert (CCList.length changes = 1);
      CCList.iter
        (fun c ->
          let module Tcm = Terrat_change_matcher in
          let module Trcwm = Terrat_repo_config.When_modified in
          let module Tcds = Terrat_change.Dirspaceflow in
          let module Ds = Terrat_change.Dirspace in
          match c.Tcm.dirspaceflow.Tcds.dirspace.Ds.dir with
          | "null_file_patterns" ->
              assert (not c.Tcm.when_modified.Trcwm.autoplan);
              assert c.Tcm.when_modified.Trcwm.autoapply
          | _ -> assert false)
        changes)

let test_bad_dir_config_iam =
  Oth.test ~name:"Test Bad Dir Config iam" (fun _ ->
      let diff = Terrat_change.Diff.[ Add { filename = "iam/foo.tf" } ] in
      let changes = Terrat_change_matcher.match_diff bad_dirs_config diff in
      (* matches s3 and iam *)
      assert (CCList.length changes = 2))

let test_bad_dir_config_ec2 =
  Oth.test ~name:"Test Bad Dir Config ec2" (fun _ ->
      let diff = Terrat_change.Diff.[ Add { filename = "ec2/foo.tf" } ] in
      let changes = Terrat_change_matcher.match_diff bad_dirs_config diff in
      (* matches s3 *)
      assert (CCList.length changes = 1))

let test_bad_dir_config_ec2_root_dir_change =
  Oth.test ~name:"Test Bad Dir Config ec2 root dir change" (fun _ ->
      let diff = Terrat_change.Diff.[ Add { filename = "foo.tf" } ] in
      let changes = Terrat_change_matcher.match_diff bad_dirs_config diff in
      (* matches ., s3, and ec2 *)
      assert (CCList.length changes = 3))

let test_bad_dir_config_s3 =
  Oth.test ~name:"Test Bad Dir Config s3" (fun _ ->
      let diff = Terrat_change.Diff.[ Add { filename = "s3/foo.tf" } ] in
      let changes = Terrat_change_matcher.match_diff bad_dirs_config diff in
      assert (CCList.length changes = 1))

let test =
  Oth.parallel
    [
      test_simple;
      test_workflow_idx;
      test_dir_match;
      test_dirspace_map;
      test_dir_file_pattern;
      test_workflow_idx_tag_in_dir;
      test_workflow_idx_multiple_dirs;
      test_workflow_override;
      test_dir_config_iam;
      test_dir_config_ebl;
      test_dir_config_ebl_modules;
      test_dir_config_ebl_and_modules;
      test_dir_config_s3;
      test_dir_config_lambda_json;
      test_dir_config_module;
      test_dir_config_null_file_patterns;
      test_bad_dir_config_iam;
      test_bad_dir_config_ec2;
      test_bad_dir_config_ec2_root_dir_change;
      test_bad_dir_config_s3;
    ]

let () =
  Random.self_init ();
  Oth.run test
