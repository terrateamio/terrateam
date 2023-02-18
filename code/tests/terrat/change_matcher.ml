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
      let dirs =
        CCResult.get_exn
          (Terrat_change_match.synthesize_dir_config ~file_list:[ "ec2/ec2.tf" ] repo_config)
      in
      let changes = Terrat_change_match.match_diff_list dirs diff in
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
      let diff = Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match.synthesize_dir_config ~file_list:[ "ec2/ec2.tf" ] repo_config)
      in
      let changes = Terrat_change_match.match_diff_list dirs diff in
      assert (CCList.length changes = 1);
      let change = CCList.hd changes in
      let workflows =
        CCOption.get_or ~default:[] repo_config.Terrat_repo_config.Version_1.workflows
      in
      let workflow_idx =
        CCOption.map
          fst
          (CCList.find_idx
             (fun Terrat_repo_config.Workflow_entry.{ tag_query; _ } ->
               Terrat_change_match.match_tag_query
                 ~tag_query:(CCResult.get_exn (Terrat_tag_query.of_string tag_query))
                 change)
             workflows)
      in
      assert (workflow_idx = Some 0))

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
      let dirs =
        CCResult.get_exn
          (Terrat_change_match.synthesize_dir_config ~file_list:[ "ec2/ec2.tf" ] repo_config)
      in
      let changes = Terrat_change_match.match_diff_list dirs diff in
      assert (CCList.length changes = 1);
      let change = CCList.hd changes in
      let workflows =
        CCOption.get_or ~default:[] repo_config.Terrat_repo_config.Version_1.workflows
      in
      let workflow_idx =
        CCOption.map
          fst
          (CCList.find_idx
             (fun Terrat_repo_config.Workflow_entry.{ tag_query; _ } ->
               Terrat_change_match.match_tag_query
                 ~tag_query:(CCResult.get_exn (Terrat_tag_query.of_string tag_query))
                 change)
             workflows)
      in
      assert (workflow_idx = Some 0))

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
      let dirs =
        CCResult.get_exn
          (Terrat_change_match.synthesize_dir_config
             ~file_list:[ "ec2/ec2.tf"; "s3/s3.tf" ]
             repo_config)
      in
      let changes = Terrat_change_match.match_diff_list dirs diff in
      assert (CCList.length changes = 2);
      let change = CCList.hd changes in
      let workflows =
        CCOption.get_or ~default:[] repo_config.Terrat_repo_config.Version_1.workflows
      in
      let workflow_idx =
        CCOption.map
          fst
          (CCList.find_idx
             (fun Terrat_repo_config.Workflow_entry.{ tag_query; _ } ->
               Terrat_change_match.match_tag_query
                 ~tag_query:(CCResult.get_exn (Terrat_tag_query.of_string tag_query))
                 change)
             workflows)
      in
      assert (workflow_idx = Some 0))

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
      let dirs =
        CCResult.get_exn
          (Terrat_change_match.synthesize_dir_config
             ~file_list:[ "ec2/ec2.tf"; "s3/s3.tf" ]
             repo_config)
      in
      let changes = Terrat_change_match.match_diff_list dirs diff in
      assert (CCList.length changes = 2);
      let workflows =
        CCOption.get_or ~default:[] repo_config.Terrat_repo_config.Version_1.workflows
      in
      CCList.iter
        (fun change ->
          let workflow_idx =
            CCOption.map
              fst
              (CCList.find_idx
                 (fun Terrat_repo_config.Workflow_entry.{ tag_query; _ } ->
                   Terrat_change_match.match_tag_query
                     ~tag_query:(CCResult.get_exn (Terrat_tag_query.of_string tag_query))
                     change)
                 workflows)
          in
          assert (workflow_idx = Some 0))
        changes)

let test_dir_match =
  Oth.test ~name:"Test dir match" (fun _ ->
      let repo_config = CCResult.get_exn (Terrat_repo_config.Version_1.of_yojson (`Assoc [])) in
      let diff =
        Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" }; Add { filename = "s3/s3.tf" } ]
      in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match.synthesize_dir_config
             ~file_list:[ "ec2/ec2.tf"; "s3/s3.tf" ]
             repo_config)
      in
      let changes =
        CCList.filter
          (Terrat_change_match.match_tag_query
             ~tag_query:(CCResult.get_exn (Terrat_tag_query.of_string "dir:ec2")))
          (Terrat_change_match.match_diff_list dirs diff)
      in
      assert (CCList.length changes = 1))

let test_dirspace_map =
  Oth.test ~name:"Test dirspace map" (fun _ ->
      let repo_config = CCResult.get_exn (Terrat_repo_config.Version_1.of_yojson (`Assoc [])) in
      let dirspaces =
        Terrat_change.Dirspace.
          [ { dir = "ec2"; workspace = "default" }; { dir = "s3"; workspace = "default" } ]
      in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match.synthesize_dir_config
             ~file_list:[ "ec2/ec2.tf"; "s3/s3.tf" ]
             repo_config)
      in
      let changes =
        CCList.filter
          (Terrat_change_match.match_tag_query
             ~tag_query:(CCResult.get_exn (Terrat_tag_query.of_string "dir:ec2")))
          (CCList.flat_map
             CCFun.(Terrat_change_match.of_dirspace dirs %> CCOption.to_list)
             dirspaces)
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
      let dirs =
        CCResult.get_exn
          (Terrat_change_match.synthesize_dir_config
             ~file_list:[ "ec2/ec2.tf"; "s3/s3.tf" ]
             repo_config)
      in
      let changes = Terrat_change_match.match_diff_list dirs diff in
      assert (CCList.length changes = 2))

let test_dir_config_iam =
  Oth.test ~name:"Test Dir Config IAM" (fun _ ->
      let diff = Terrat_change.Diff.[ Add { filename = "iam/foo.tf" } ] in
      let dirs =
        match
          Terrat_change_match.synthesize_dir_config
            ~file_list:[ "iam/foo.tf"; "ec2/ec2.tf"; "ebl/ebl.tf"; "lambda/lambda.tf" ]
            dirs_config
        with
        | Ok dirs -> dirs
        | Error (`Bad_glob s) -> failwith s
      in
      let changes = Terrat_change_match.match_diff_list dirs diff in
      (* We match the iam and ec2 dir *)
      assert (CCList.length changes = 2);
      CCList.iter
        (fun Terrat_change_match.{ dirspace = Terrat_change.Dirspace.{ dir; _ }; when_modified; _ } ->
          let module Wm = Terrat_repo_config.When_modified in
          match dir with
          | "ec2" ->
              assert (not when_modified.Wm.autoplan);
              assert when_modified.Wm.autoapply
          | "iam" ->
              assert (not when_modified.Wm.autoplan);
              assert when_modified.Wm.autoapply
          | _ -> assert false)
        changes)

let test_dir_config_ebl =
  Oth.test ~name:"Test Dir Config ebl" (fun _ ->
      let diff = Terrat_change.Diff.[ Add { filename = "ebl/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match.synthesize_dir_config
             ~file_list:[ "iam/foo.tf"; "ec2/ec2.tf"; "ebl/ebl.tf"; "lambda/lambda.tf" ]
             dirs_config)
      in
      let changes = Terrat_change_match.match_diff_list dirs diff in
      assert (CCList.length changes = 1);
      CCList.iter
        (fun Terrat_change_match.{ dirspace = Terrat_change.Dirspace.{ dir; _ }; when_modified; _ } ->
          let module Wm = Terrat_repo_config.When_modified in
          match dir with
          | "ebl" ->
              assert (not when_modified.Wm.autoplan);
              assert when_modified.Wm.autoapply
          | _ -> assert false)
        changes)

let test_dir_config_ebl_modules =
  Oth.test ~name:"Test Dir Config ebl modules" (fun _ ->
      let diff = Terrat_change.Diff.[ Add { filename = "ebl_modules" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match.synthesize_dir_config
             ~file_list:
               [ "iam/foo.tf"; "ec2/ec2.tf"; "ebl/ebl.tf"; "lambda/lambda.tf"; "ebl_modules" ]
             dirs_config)
      in
      let changes = Terrat_change_match.match_diff_list dirs diff in
      assert (CCList.length changes = 1);
      CCList.iter
        (fun Terrat_change_match.{ dirspace = Terrat_change.Dirspace.{ dir; _ }; when_modified; _ } ->
          let module Wm = Terrat_repo_config.When_modified in
          match dir with
          | "ebl" ->
              assert (not when_modified.Wm.autoplan);
              assert when_modified.Wm.autoapply
          | _ -> assert false)
        changes)

let test_dir_config_ebl_and_modules =
  Oth.test ~name:"Test Dir Config ebl and modules" (fun _ ->
      let diff =
        Terrat_change.Diff.[ Add { filename = "ebl_modules" }; Add { filename = "ebl/foo.tf" } ]
      in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match.synthesize_dir_config
             ~file_list:
               [ "iam/foo.tf"; "ec2/ec2.tf"; "ebl/ebl.tf"; "lambda/lambda.tf"; "ebl_modules" ]
             dirs_config)
      in
      let changes = Terrat_change_match.match_diff_list dirs diff in
      assert (CCList.length changes = 1);
      CCList.iter
        (fun Terrat_change_match.{ dirspace = Terrat_change.Dirspace.{ dir; _ }; when_modified; _ } ->
          let module Wm = Terrat_repo_config.When_modified in
          match dir with
          | "ebl" ->
              assert (not when_modified.Wm.autoplan);
              assert when_modified.Wm.autoapply
          | _ -> assert false)
        changes)

let test_dir_config_s3 =
  Oth.test ~name:"Test Dir Config s3" (fun _ ->
      let diff = Terrat_change.Diff.[ Add { filename = "s3/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match.synthesize_dir_config
             ~file_list:
               [
                 "iam/foo.tf";
                 "ec2/ec2.tf";
                 "ebl/ebl.tf";
                 "lambda/lambda.tf";
                 "ebl_modules";
                 "s3/s3.tf";
               ]
             dirs_config)
      in
      let changes = Terrat_change_match.match_diff_list dirs diff in
      assert (CCList.length changes = 1);
      CCList.iter
        (fun Terrat_change_match.{ dirspace = Terrat_change.Dirspace.{ dir; _ }; when_modified; _ } ->
          let module Wm = Terrat_repo_config.When_modified in
          match dir with
          | "s3" ->
              assert (not when_modified.Wm.autoplan);
              assert when_modified.Wm.autoapply
          | _ -> assert false)
        changes)

let test_dir_config_lambda_json =
  Oth.test ~name:"Test Dir Config lambda JSON" (fun _ ->
      let diff = Terrat_change.Diff.[ Add { filename = "lambda/foo.json" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match.synthesize_dir_config
             ~file_list:
               [
                 "iam/foo.tf";
                 "ec2/ec2.tf";
                 "ebl/ebl.tf";
                 "lambda/foo.tf";
                 "ebl_modules";
                 "s3/s3.tf";
               ]
             dirs_config)
      in
      let changes = Terrat_change_match.match_diff_list dirs diff in
      assert (CCList.length changes = 1);
      CCList.iter
        (fun Terrat_change_match.{ dirspace = Terrat_change.Dirspace.{ dir; _ }; when_modified; _ } ->
          let module Wm = Terrat_repo_config.When_modified in
          match dir with
          | "lambda" ->
              assert when_modified.Wm.autoplan;
              assert when_modified.Wm.autoapply
          | _ -> assert false)
        changes)

let test_dir_config_module =
  Oth.test ~name:"Test Dir Config module" (fun _ ->
      let diff = Terrat_change.Diff.[ Add { filename = "module/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match.synthesize_dir_config
             ~file_list:
               [
                 "iam/foo.tf";
                 "ec2/ec2.tf";
                 "ebl/ebl.tf";
                 "lambda/foo.tf";
                 "ebl_modules";
                 "s3/s3.tf";
                 "module/foo.tf";
               ]
             dirs_config)
      in
      let changes = Terrat_change_match.match_diff_list dirs diff in
      assert (CCList.length changes = 0))

let test_dir_config_null_file_patterns =
  Oth.test ~name:"Test Dir Config null_file_patterns" (fun _ ->
      let diff = Terrat_change.Diff.[ Add { filename = "null_file_patterns/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match.synthesize_dir_config
             ~file_list:
               [
                 "iam/foo.tf";
                 "ec2/ec2.tf";
                 "ebl/ebl.tf";
                 "lambda/foo.tf";
                 "ebl_modules";
                 "s3/s3.tf";
                 "module/foo.tf";
                 "null_file_patterns/foo.tf";
               ]
             dirs_config)
      in
      let changes = Terrat_change_match.match_diff_list dirs diff in
      assert (CCList.length changes = 1);
      CCList.iter
        (fun Terrat_change_match.{ dirspace = Terrat_change.Dirspace.{ dir; _ }; when_modified; _ } ->
          let module Wm = Terrat_repo_config.When_modified in
          match dir with
          | "null_file_patterns" ->
              assert (not when_modified.Wm.autoplan);
              assert when_modified.Wm.autoapply
          | _ -> assert false)
        changes)

let test_recursive_dirs_template_dir =
  Oth.test ~name:"Test Recursive Dirs Template Dir" (fun _ ->
      let dirs_config =
        CCResult.get_exn
          (Terrat_repo_config.Version_1.of_yojson
             (`Assoc
               [
                 ( "dirs",
                   `Assoc
                     [
                       ( "_template/*",
                         `Assoc [ ("when_modified", `Assoc [ ("file_patterns", `List []) ]) ] );
                       ( "aws/**/terragrunt.hcl",
                         `Assoc
                           [
                             ( "when_modified",
                               `Assoc
                                 [
                                   ( "file_patterns",
                                     `List [ `String "_templates/**/*.tf"; `String "${DIR}/*.hcl" ]
                                   );
                                 ] );
                           ] );
                     ] );
               ]))
      in
      let file_list =
        [
          "_template/aws/terragrunt.hcl";
          "_template/aws/staging/terragrunt.hcl";
          "aws/staging/us-east-1/terragrunt.hcl";
          "aws/prod/us-east-1/terragrunt.hcl";
        ]
      in
      let diff = Terrat_change.Diff.[ Add { filename = "_template/aws/terragrunt.hcl" } ] in
      let dirs =
        CCResult.get_exn (Terrat_change_match.synthesize_dir_config ~file_list dirs_config)
      in
      let changes = Terrat_change_match.match_diff_list dirs diff in
      assert (CCList.length changes = 0))

let test_recursive_dirs_aws_prod =
  Oth.test ~name:"Test Recursive Dirs AWS Prod" (fun _ ->
      let dirs_config =
        CCResult.get_exn
          (Terrat_repo_config.Version_1.of_yojson
             (`Assoc
               [
                 ( "dirs",
                   `Assoc
                     [
                       ( "_template/*",
                         `Assoc [ ("when_modified", `Assoc [ ("file_patterns", `List []) ]) ] );
                       ( "aws/**/terragrunt.hcl",
                         `Assoc
                           [
                             ( "when_modified",
                               `Assoc
                                 [
                                   ( "file_patterns",
                                     `List [ `String "_templates/**/*.tf"; `String "${DIR}/*.hcl" ]
                                   );
                                 ] );
                           ] );
                     ] );
               ]))
      in
      let file_list =
        [
          "_template/aws/terragrunt.hcl";
          "_template/aws/staging/terragrunt.hcl";
          "aws/staging/us-east-1/terragrunt.hcl";
          "aws/prod/us-east-1/terragrunt.hcl";
        ]
      in
      let diff = Terrat_change.Diff.[ Add { filename = "aws/prod/us-east-1/terragrunt.hcl" } ] in
      let dirs =
        CCResult.get_exn (Terrat_change_match.synthesize_dir_config ~file_list dirs_config)
      in
      let changes = Terrat_change_match.match_diff_list dirs diff in
      assert (CCList.length changes = 1))

let test_recursive_dirs_tags =
  Oth.test ~name:"Test Recursive Dirs With Tags" (fun _ ->
      let dirs_config =
        CCResult.get_exn
          (Terrat_repo_config.Version_1.of_yojson
             (`Assoc
               [
                 ( "dirs",
                   `Assoc
                     [
                       ( "_template/*",
                         `Assoc [ ("when_modified", `Assoc [ ("file_patterns", `List []) ]) ] );
                       ( "aws/**/secrets-manager/**/terragrunt.hcl",
                         `Assoc
                           [
                             ("tags", `List [ `String "secrets" ]);
                             ( "when_modified",
                               `Assoc [ ("file_patterns", `List [ `String "${DIR}/*.hcl" ]) ] );
                           ] );
                       ( "aws/**/terragrunt.hcl",
                         `Assoc
                           [
                             ( "when_modified",
                               `Assoc [ ("file_patterns", `List [ `String "${DIR}/*.hcl" ]) ] );
                           ] );
                     ] );
               ]))
      in
      let file_list =
        [
          "_template/aws/terragrunt.hcl";
          "_template/aws/staging/terragrunt.hcl";
          "aws/staging/us-east-1/terragrunt.hcl";
          "aws/prod/us-east-1/terragrunt.hcl";
          "aws/prod/secrets-manager/us-east-1/terragrunt.hcl";
        ]
      in
      let diff =
        Terrat_change.Diff.
          [
            Add { filename = "aws/prod/us-east-1/terragrunt.hcl" };
            Add { filename = "aws/prod/secrets-manager/us-east-1/terragrunt.hcl" };
          ]
      in
      let dirs =
        CCResult.get_exn (Terrat_change_match.synthesize_dir_config ~file_list dirs_config)
      in
      let changes =
        CCList.filter
          (Terrat_change_match.match_tag_query
             ~tag_query:(CCResult.get_exn (Terrat_tag_query.of_string "secrets")))
          (Terrat_change_match.match_diff_list dirs diff)
      in
      assert (CCList.length changes = 1);
      CCList.iter
        (fun Terrat_change_match.{ dirspace = Terrat_change.Dirspace.{ dir; _ }; when_modified; _ } ->
          let module Wm = Terrat_repo_config.When_modified in
          match dir with
          | "aws/prod/secrets-manager/us-east-1" ->
              assert when_modified.Wm.autoplan;
              assert (not when_modified.Wm.autoapply)
          | _ -> assert false)
        changes)

let test_recursive_dirs_without_tags =
  Oth.test ~name:"Test Recursive Dirs Without Tags" (fun _ ->
      let dirs_config =
        CCResult.get_exn
          (Terrat_repo_config.Version_1.of_yojson
             (`Assoc
               [
                 ( "dirs",
                   `Assoc
                     [
                       ( "_template/*",
                         `Assoc [ ("when_modified", `Assoc [ ("file_patterns", `List []) ]) ] );
                       ( "aws/**/secrets-manager/**/terragrunt.hcl",
                         `Assoc
                           [
                             ("tags", `List [ `String "secrets" ]);
                             ( "when_modified",
                               `Assoc [ ("file_patterns", `List [ `String "${DIR}/*.hcl" ]) ] );
                           ] );
                       ( "aws/**/terragrunt.hcl",
                         `Assoc
                           [
                             ( "when_modified",
                               `Assoc [ ("file_patterns", `List [ `String "${DIR}/*.hcl" ]) ] );
                           ] );
                     ] );
               ]))
      in
      let file_list =
        [
          "_template/aws/terragrunt.hcl";
          "_template/aws/staging/terragrunt.hcl";
          "aws/staging/us-east-1/terragrunt.hcl";
          "aws/prod/us-east-1/terragrunt.hcl";
          "aws/prod/secrets-manager/us-east-1/terragrunt.hcl";
        ]
      in
      let diff =
        Terrat_change.Diff.
          [
            Add { filename = "aws/prod/us-east-1/terragrunt.hcl" };
            Add { filename = "aws/prod/secrets-manager/us-east-1/terragrunt.hcl" };
          ]
      in
      let dirs =
        CCResult.get_exn (Terrat_change_match.synthesize_dir_config ~file_list dirs_config)
      in
      let changes = Terrat_change_match.match_diff_list dirs diff in
      assert (CCList.length changes = 1);
      CCList.iter
        (fun Terrat_change_match.{ dirspace = Terrat_change.Dirspace.{ dir; _ }; when_modified; _ } ->
          let module Wm = Terrat_repo_config.When_modified in
          match dir with
          | "aws/prod/secrets-manager/us-east-1" | "aws/prod/us-east-1" ->
              assert when_modified.Wm.autoplan;
              assert (not when_modified.Wm.autoapply)
          | _ -> assert false)
        changes)

let test_bad_glob =
  Oth.test ~name:"Test Bad glob" (fun _ ->
      let dirs_config =
        CCResult.get_exn
          (Terrat_repo_config.Version_1.of_yojson
             (`Assoc
               [
                 ( "dirs",
                   `Assoc
                     [
                       ( "_template/*",
                         `Assoc [ ("when_modified", `Assoc [ ("file_patterns", `List []) ]) ] );
                       ( "aws",
                         `Assoc
                           [
                             ( "when_modified",
                               `Assoc
                                 [
                                   ( "file_patterns",
                                     `List [ `String "_templates/**/*.tf"; `String "${DIR}/*.hcl" ]
                                   );
                                 ] );
                           ] );
                     ] );
               ]))
      in
      let file_list =
        [
          "_template/aws/terragrunt.hcl";
          "_template/aws/staging/terragrunt.hcl";
          "aws/staging/us-east-1/terragrunt.hcl";
          "aws/prod/us-east-1/terragrunt.hcl";
        ]
      in
      let result = Terrat_change_match.synthesize_dir_config ~file_list dirs_config in
      assert (result = Error (`Bad_glob "${DIR}/*.hcl")))

let test_bad_dir_config_iam =
  Oth.test ~name:"Test Bad Dir Config iam" (fun _ ->
      let diff = Terrat_change.Diff.[ Add { filename = "iam/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match.synthesize_dir_config
             ~file_list:
               [ "ec2/ec2.tf"; "iam/foo.tf"; "ebl/ebl.tf"; "s3/s3.tf"; "s3/foo.tf"; "foo.tf" ]
             bad_dirs_config)
      in
      let changes = Terrat_change_match.match_diff_list dirs diff in
      (* matches s3 and iam *)
      assert (CCList.length changes = 2))

let test_bad_dir_config_ec2 =
  Oth.test ~name:"Test Bad Dir Config ec2" (fun _ ->
      let diff = Terrat_change.Diff.[ Add { filename = "ec2/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match.synthesize_dir_config
             ~file_list:
               [ "ec2/ec2.tf"; "iam/foo.tf"; "ebl/ebl.tf"; "s3/s3.tf"; "s3/foo.tf"; "foo.tf" ]
             bad_dirs_config)
      in
      let changes = Terrat_change_match.match_diff_list dirs diff in
      (* matches s3 *)
      assert (CCList.length changes = 1))

let test_bad_dir_config_ec2_root_dir_change =
  Oth.test ~name:"Test Bad Dir Config ec2 root dir change" (fun _ ->
      let diff = Terrat_change.Diff.[ Add { filename = "foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match.synthesize_dir_config
             ~file_list:[ "ec2/ec2.tf"; "iam/foo.tf"; "ebl/ebl.tf"; "s3/s3.tf"; "foo.tf" ]
             bad_dirs_config)
      in
      let changes = Terrat_change_match.match_diff_list dirs diff in
      (* matches ., s3, and ec2 *)
      assert (CCList.length changes = 3))

let test_bad_dir_config_s3 =
  Oth.test ~name:"Test Bad Dir Config s3" (fun _ ->
      let diff = Terrat_change.Diff.[ Add { filename = "s3/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match.synthesize_dir_config
             ~file_list:
               [ "ec2/ec2.tf"; "iam/foo.tf"; "ebl/ebl.tf"; "s3/s3.tf"; "s3/foo.tf"; "foo.tf" ]
             bad_dirs_config)
      in
      let changes = Terrat_change_match.match_diff_list dirs diff in
      assert (CCList.length changes = 1))

let test_module_dir_with_root_dir =
  Oth.test ~name:"Test module dir with root dir" (fun _ ->
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
                       ( "module",
                         `Assoc [ ("when_modified", `Assoc [ ("file_patterns", `List []) ]) ] );
                       ( ".",
                         `Assoc
                           [
                             ( "when_modified",
                               `Assoc
                                 [
                                   ( "file_patterns",
                                     `List [ `String "./*.tf"; `String "module/**/*.tf" ] );
                                 ] );
                           ] );
                     ] );
               ]))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "module/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match.synthesize_dir_config
             ~file_list:[ "foo.tf"; "module/foo/tf.tf" ]
             dirs_config)
      in
      let changes = Terrat_change_match.match_diff_list dirs diff in
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
      test_recursive_dirs_template_dir;
      test_recursive_dirs_aws_prod;
      test_recursive_dirs_tags;
      (* test_bad_glob; *)
      test_bad_dir_config_iam;
      test_bad_dir_config_ec2;
      (* test_bad_dir_config_ec2_root_dir_change; *)
      test_bad_dir_config_s3;
      test_module_dir_with_root_dir;
    ]

let () =
  Random.self_init ();
  Oth.run test
