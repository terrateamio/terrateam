let ctx = Terrat_base_repo_config_v1.Ctx.make ~dest_branch:"main" ~branch:"test" ()

(* This configuration is used for tests of the dirs configuration *)
let dirs_config =
  let module R = Terrat_base_repo_config_v1 in
  let default_file_patterns =
    [
      CCResult.get_exn (R.File_pattern.make "${DIR}/*.tf");
      CCResult.get_exn (R.File_pattern.make "${DIR}/*.tfvars");
      CCResult.get_exn (R.File_pattern.make "${DIR}/*.json");
    ]
  in
  let when_modified =
    R.When_modified.make ~autoapply:true ~autoplan:false ~file_patterns:default_file_patterns ()
  in
  R.of_view
    (R.View.make
       ~when_modified
       ~dirs:
         (R.String_map.of_list
            [
              ( "iam",
                R.Dirs.Dir.make
                  ~workspaces:
                    (R.String_map.of_list
                       [
                         ( "default",
                           R.Dirs.Workspace.make
                             ~when_modified:
                               {
                                 when_modified with
                                 R.When_modified.autoplan = false;
                                 file_patterns =
                                   [ CCResult.get_exn (R.File_pattern.make "iam/*.tf") ];
                               }
                             () );
                       ])
                  () );
              ( "ebl",
                R.Dirs.Dir.make
                  ~workspaces:
                    (R.String_map.of_list
                       [
                         ( "default",
                           R.Dirs.Workspace.make
                             ~when_modified:
                               {
                                 when_modified with
                                 R.When_modified.autoapply = true;
                                 file_patterns =
                                   [
                                     CCResult.get_exn (R.File_pattern.make "ebl/*.tf");
                                     CCResult.get_exn (R.File_pattern.make "ebl_modules");
                                   ];
                               }
                             () );
                       ])
                  () );
              ( "ec2",
                R.Dirs.Dir.make
                  ~workspaces:
                    (R.String_map.of_list
                       [
                         ( "default",
                           R.Dirs.Workspace.make
                             ~when_modified:
                               {
                                 when_modified with
                                 (* This actually has an error in that it does not
                                    match files in the ec2 directory, this error is
                                    on purpose used for testing. *)
                                 R.When_modified.file_patterns =
                                   [ CCResult.get_exn (R.File_pattern.make "iam/*.tf") ];
                               }
                             () );
                       ])
                  () );
              ( "s3",
                R.Dirs.Dir.make
                  ~tags:[ "s3" ]
                  ~workspaces:
                    (R.String_map.of_list [ ("default", R.Dirs.Workspace.make ~when_modified ()) ])
                  () );
              ( "lambda",
                R.Dirs.Dir.make
                  ~workspaces:
                    (R.String_map.of_list
                       [
                         ( "default",
                           R.Dirs.Workspace.make
                             ~when_modified:{ when_modified with R.When_modified.autoplan = true }
                             () );
                       ])
                  () );
              ( "module",
                R.Dirs.Dir.make
                  ~workspaces:
                    (R.String_map.of_list
                       [
                         ( "default",
                           R.Dirs.Workspace.make
                             ~when_modified:
                               { when_modified with R.When_modified.file_patterns = [] }
                             () );
                       ])
                  () );
            ])
       ())

(* this config makes the mistake of having a directory that matches everything *)
let bad_dirs_config =
  let module R = Terrat_base_repo_config_v1 in
  R.of_view
    (R.View.make
       ~dirs:
         (R.String_map.of_list
            [
              ( "iam",
                R.Dirs.Dir.make
                  ~workspaces:
                    (R.String_map.of_list
                       [
                         ( "default",
                           R.Dirs.Workspace.make
                             ~when_modified:
                               (R.When_modified.make
                                  ~file_patterns:
                                    [ CCResult.get_exn (R.File_pattern.make "iam/*.tf") ]
                                  ())
                             () );
                       ])
                  () );
              ( "ebl",
                R.Dirs.Dir.make
                  ~workspaces:
                    (R.String_map.of_list
                       [
                         ( "default",
                           R.Dirs.Workspace.make
                             ~when_modified:
                               (R.When_modified.make
                                  ~file_patterns:
                                    [
                                      CCResult.get_exn (R.File_pattern.make "ebl/*.tf");
                                      CCResult.get_exn (R.File_pattern.make "ebl_modules");
                                    ]
                                  ())
                             () );
                       ])
                  () );
              ( "ec2",
                R.Dirs.Dir.make
                  ~workspaces:
                    (R.String_map.of_list
                       [
                         ( "default",
                           R.Dirs.Workspace.make
                             ~when_modified:
                               (R.When_modified.make
                                (* This should only match changes in the root
                                   directory, no subdirs *)
                                  ~file_patterns:[ CCResult.get_exn (R.File_pattern.make "*.tf") ]
                                  ())
                             () );
                       ])
                  () );
              ( "s3",
                R.Dirs.Dir.make
                  ~workspaces:
                    (R.String_map.of_list
                       [
                         ( "default",
                           R.Dirs.Workspace.make
                             ~when_modified:
                               (R.When_modified.make
                                  ~file_patterns:
                                    [ CCResult.get_exn (R.File_pattern.make "**/*.tf") ]
                                  ())
                             () );
                       ])
                  () );
            ])
       ())

let test_simple =
  Oth.test ~name:"Test simple" (fun _ ->
      let repo_config =
        Terrat_base_repo_config_v1.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf" ]
          Terrat_base_repo_config_v1.default
      in
      let diff = Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = Terrat_change_match3.match_diff_list dirs diff in
      assert (CCList.length changes = 1))

let test_workflow_idx =
  Oth.test ~name:"Test workflow idx" (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf" ]
          (R.of_view
             (R.View.make
                ~workflows:
                  [
                    R.Workflows.Entry.make
                      ~tag_query:(CCResult.get_exn (Terrat_tag_query.of_string "workspace:default"))
                      ~plan:
                        [
                          R.Workflows.Entry.Op.Run
                            (R.Workflow_step.Run.make ~cmd:[ "echo"; "hi" ] ());
                        ]
                      ();
                  ]
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 1);
      let change = CCList.hd changes in
      let workflows = Terrat_base_repo_config_v1.workflows repo_config in
      let workflow_idx =
        CCOption.map
          fst
          (CCList.find_idx
             (fun { Terrat_base_repo_config_v1.Workflows.Entry.tag_query; _ } ->
               Terrat_change_match3.match_tag_query ~tag_query change)
             workflows)
      in
      assert (workflow_idx = Some 0))

let test_workflow_idx_tag_in_dir =
  Oth.test
    ~name:"Test workflow idx tag in dir"
    ~desc:"Test workflow idx matches when tag is in dirs"
    (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf" ]
          (R.of_view
             (R.View.make
                ~workflows:
                  [
                    R.Workflows.Entry.make
                      ~tag_query:(CCResult.get_exn (Terrat_tag_query.of_string "ec2"))
                      ~plan:
                        [
                          R.Workflows.Entry.Op.Run
                            (R.Workflow_step.Run.make ~cmd:[ "echo"; "hi" ] ());
                        ]
                      ();
                  ]
                ~dirs:(R.String_map.of_list [ ("ec2", R.Dirs.Dir.make ~tags:[ "ec2" ] ()) ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 1);
      let change = CCList.hd changes in
      let workflows = Terrat_base_repo_config_v1.workflows repo_config in
      let workflow_idx =
        CCOption.map
          fst
          (CCList.find_idx
             (fun { Terrat_base_repo_config_v1.Workflows.Entry.tag_query; _ } ->
               Terrat_change_match3.match_tag_query ~tag_query change)
             workflows)
      in
      assert (workflow_idx = Some 0))

let test_workflow_idx_multiple_dirs =
  Oth.test
    ~name:"Test workflow idx multiple dirs"
    ~desc:"Test workflow idx matches when tag is in dirs with multiple dirs changed"
    (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf"; "s3/s3.tf" ]
          (R.of_view
             (R.View.make
                ~workflows:
                  [
                    R.Workflows.Entry.make
                      ~tag_query:(CCResult.get_exn (Terrat_tag_query.of_string "ec2"))
                      ~plan:
                        [
                          R.Workflows.Entry.Op.Run
                            (R.Workflow_step.Run.make ~cmd:[ "echo"; "hi" ] ());
                        ]
                      ();
                  ]
                ~dirs:
                  (R.String_map.of_list
                     [
                       ("ec2", R.Dirs.Dir.make ~tags:[ "ec2" ] ());
                       ("s3", R.Dirs.Dir.make ~tags:[ "s3" ] ());
                     ])
                ()))
      in
      let diff =
        Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" }; Add { filename = "s3/s3.tf" } ]
      in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 2);
      let change =
        CCList.hd
          (CCList.filter
             (fun { Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; _ }; _ }
                -> dir = "ec2")
             changes)
      in
      let workflows = Terrat_base_repo_config_v1.workflows repo_config in
      let workflow_idx =
        CCOption.map
          fst
          (CCList.find_idx
             (fun { Terrat_base_repo_config_v1.Workflows.Entry.tag_query; _ } ->
               Terrat_change_match3.match_tag_query ~tag_query change)
             workflows)
      in
      assert (workflow_idx = Some 0))

let test_workflow_override =
  Oth.test ~name:"Test overriding workflow for all" (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf"; "s3/s3.tf" ]
          (R.of_view
             (R.View.make
                ~workflows:
                  [
                    R.Workflows.Entry.make
                      ~tag_query:(CCResult.get_exn (Terrat_tag_query.of_string ""))
                      ~plan:
                        [
                          R.Workflows.Entry.Op.Run
                            (R.Workflow_step.Run.make ~cmd:[ "echo"; "hi" ] ());
                        ]
                      ();
                  ]
                ()))
      in
      let diff =
        Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" }; Add { filename = "s3/s3.tf" } ]
      in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 2);
      let workflows = Terrat_base_repo_config_v1.workflows repo_config in
      CCList.iter
        (fun change ->
          let workflow_idx =
            CCOption.map
              fst
              (CCList.find_idx
                 (fun { Terrat_base_repo_config_v1.Workflows.Entry.tag_query; _ } ->
                   Terrat_change_match3.match_tag_query ~tag_query change)
                 workflows)
          in
          assert (workflow_idx = Some 0))
        changes)

let test_dir_match =
  Oth.test ~name:"Test dir match" (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf"; "s3/s3.tf" ]
          R.default
      in
      let diff =
        Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" }; Add { filename = "s3/s3.tf" } ]
      in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes =
        CCList.filter
          (Terrat_change_match3.match_tag_query
             ~tag_query:(CCResult.get_exn (Terrat_tag_query.of_string "dir:ec2")))
          (CCList.flatten (Terrat_change_match3.match_diff_list dirs diff))
      in
      assert (CCList.length changes = 1))

let test_dirspace_map =
  Oth.test ~name:"Test dirspace map" (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf"; "s3/s3.tf" ]
          R.default
      in
      let dirspaces =
        Terrat_change.Dirspace.
          [ { dir = "ec2"; workspace = "default" }; { dir = "s3"; workspace = "default" } ]
      in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes =
        CCList.filter
          (Terrat_change_match3.match_tag_query
             ~tag_query:(CCResult.get_exn (Terrat_tag_query.of_string "dir:ec2")))
          (CCList.flat_map
             CCFun.(Terrat_change_match3.of_dirspace dirs %> CCOption.to_list)
             dirspaces)
      in
      assert (CCList.length changes = 1))

let test_dir_file_pattern =
  Oth.test ~name:"Test dir file pattern" (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf"; "s3/s3.tf" ]
          (R.of_view
             (R.View.make
                ~dirs:
                  (R.String_map.of_list
                     [
                       ( "iam",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [ CCResult.get_exn (R.File_pattern.make "ec2/*.tf") ]
                                           ())
                                      () );
                                ])
                           () );
                       ("s3", R.Dirs.Dir.make ~tags:[ "s3" ] ());
                     ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 2))

let test_dir_config_iam =
  Oth.test ~name:"Test Dir Config IAM" (fun _ ->
      let repo_config =
        Terrat_base_repo_config_v1.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "iam/foo.tf"; "ec2/ec2.tf"; "ebl/ebl.tf"; "lambda/lambda.tf" ]
          dirs_config
      in
      let diff = Terrat_change.Diff.[ Add { filename = "iam/foo.tf" } ] in
      let dirs =
        match
          Terrat_change_match3.synthesize_config
            ~index:Terrat_base_repo_config_v1.Index.empty
            repo_config
        with
        | Ok dirs -> dirs
        | Error _ -> assert false
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      (* We match the iam and ec2 dir *)
      assert (CCList.length changes = 2);
      CCList.iter
        (fun {
               Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; _ };
               when_modified;
               _;
             }
           ->
          let module Wm = Terrat_base_repo_config_v1.When_modified in
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
      let repo_config =
        Terrat_base_repo_config_v1.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "iam/foo.tf"; "ec2/ec2.tf"; "ebl/ebl.tf"; "lambda/lambda.tf" ]
          dirs_config
      in
      let diff = Terrat_change.Diff.[ Add { filename = "ebl/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 1);
      CCList.iter
        (fun {
               Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; _ };
               when_modified;
               _;
             }
           ->
          let module Wm = Terrat_base_repo_config_v1.When_modified in
          match dir with
          | "ebl" ->
              assert (not when_modified.Wm.autoplan);
              assert when_modified.Wm.autoapply
          | _ -> assert false)
        changes)

let test_dir_config_ebl_modules =
  Oth.test ~name:"Test Dir Config ebl modules" (fun _ ->
      let repo_config =
        Terrat_base_repo_config_v1.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "iam/foo.tf"; "ec2/ec2.tf"; "ebl/ebl.tf"; "lambda/lambda.tf"; "ebl_modules" ]
          dirs_config
      in
      let diff = Terrat_change.Diff.[ Add { filename = "ebl_modules" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 1);
      CCList.iter
        (fun {
               Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; _ };
               when_modified;
               _;
             }
           ->
          let module Wm = Terrat_base_repo_config_v1.When_modified in
          match dir with
          | "ebl" ->
              assert (not when_modified.Wm.autoplan);
              assert when_modified.Wm.autoapply
          | _ -> assert false)
        changes)

let test_dir_config_ebl_and_modules =
  Oth.test ~name:"Test Dir Config ebl and modules" (fun _ ->
      let repo_config =
        Terrat_base_repo_config_v1.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "iam/foo.tf"; "ec2/ec2.tf"; "ebl/ebl.tf"; "lambda/lambda.tf"; "ebl_modules" ]
          dirs_config
      in
      let diff =
        Terrat_change.Diff.[ Add { filename = "ebl_modules" }; Add { filename = "ebl/foo.tf" } ]
      in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 1);
      CCList.iter
        (fun {
               Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; _ };
               when_modified;
               _;
             }
           ->
          let module Wm = Terrat_base_repo_config_v1.When_modified in
          match dir with
          | "ebl" ->
              assert (not when_modified.Wm.autoplan);
              assert when_modified.Wm.autoapply
          | _ -> assert false)
        changes)

let test_dir_config_s3 =
  Oth.test ~name:"Test Dir Config s3" (fun _ ->
      let repo_config =
        Terrat_base_repo_config_v1.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:
            [
              "iam/foo.tf";
              "ec2/ec2.tf";
              "ebl/ebl.tf";
              "lambda/lambda.tf";
              "ebl_modules";
              "s3/s3.tf";
            ]
          dirs_config
      in
      let diff = Terrat_change.Diff.[ Add { filename = "s3/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 1);
      CCList.iter
        (fun {
               Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; _ };
               when_modified;
               _;
             }
           ->
          let module Wm = Terrat_base_repo_config_v1.When_modified in
          match dir with
          | "s3" ->
              assert (not when_modified.Wm.autoplan);
              assert when_modified.Wm.autoapply
          | _ -> assert false)
        changes)

let test_dir_config_lambda_json =
  Oth.test ~name:"Test Dir Config lambda JSON" (fun _ ->
      let repo_config =
        Terrat_base_repo_config_v1.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:
            [ "iam/foo.tf"; "ec2/ec2.tf"; "ebl/ebl.tf"; "lambda/foo.tf"; "ebl_modules"; "s3/s3.tf" ]
          dirs_config
      in
      let diff = Terrat_change.Diff.[ Add { filename = "lambda/foo.json" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 1);
      CCList.iter
        (fun {
               Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; _ };
               when_modified;
               _;
             }
           ->
          let module Wm = Terrat_base_repo_config_v1.When_modified in
          match dir with
          | "lambda" ->
              assert when_modified.Wm.autoplan;
              assert when_modified.Wm.autoapply
          | _ -> assert false)
        changes)

let test_dir_config_module =
  Oth.test ~name:"Test Dir Config module" (fun _ ->
      let repo_config =
        Terrat_base_repo_config_v1.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
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
          dirs_config
      in
      let diff = Terrat_change.Diff.[ Add { filename = "module/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 0))

let test_dir_config_null_file_patterns =
  Oth.test ~name:"Test Dir Config null_file_patterns" (fun _ ->
      let repo_config =
        Terrat_base_repo_config_v1.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
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
          dirs_config
      in
      let diff = Terrat_change.Diff.[ Add { filename = "null_file_patterns/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 1);
      CCList.iter
        (fun {
               Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; _ };
               when_modified;
               _;
             }
           ->
          let module Wm = Terrat_base_repo_config_v1.When_modified in
          match dir with
          | "null_file_patterns" ->
              assert (not when_modified.Wm.autoplan);
              assert when_modified.Wm.autoapply
          | _ -> assert false)
        changes)

let test_recursive_dirs_template_dir =
  Oth.test ~name:"Test Recursive Dirs Template Dir" (fun _ ->
      let file_list =
        [
          "_template/aws/terragrunt.hcl";
          "_template/aws/staging/terragrunt.hcl";
          "aws/staging/us-east-1/terragrunt.hcl";
          "aws/prod/us-east-1/terragrunt.hcl";
        ]
      in

      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (R.String_map.of_list
                     [
                       ( "_template/*",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:(R.When_modified.make ~file_patterns:[] ())
                                      () );
                                ])
                           () );
                       ( "aws/**/terragrunt.hcl",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [
                                               CCResult.get_exn
                                                 (R.File_pattern.make "_templates/**/*.tf");
                                               CCResult.get_exn (R.File_pattern.make "${DIR}/*.hcl");
                                             ]
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "_template/aws/terragrunt.hcl" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 0))

let test_recursive_dirs_aws_prod =
  Oth.test ~name:"Test Recursive Dirs AWS Prod" (fun _ ->
      let file_list =
        [
          "_template/aws/terragrunt.hcl";
          "_template/aws/staging/terragrunt.hcl";
          "aws/staging/us-east-1/terragrunt.hcl";
          "aws/prod/us-east-1/terragrunt.hcl";
        ]
      in

      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (R.String_map.of_list
                     [
                       ( "_template/*",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:(R.When_modified.make ~file_patterns:[] ())
                                      () );
                                ])
                           () );
                       ( "aws/**/terragrunt.hcl",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [
                                               CCResult.get_exn
                                                 (R.File_pattern.make "_templates/**/*.tf");
                                               CCResult.get_exn (R.File_pattern.make "${DIR}/*.hcl");
                                             ]
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "aws/prod/us-east-1/terragrunt.hcl" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 1))

let test_recursive_dirs_tags =
  Oth.test ~name:"Test Recursive Dirs With Tags" (fun _ ->
      let file_list =
        [
          "_template/aws/terragrunt.hcl";
          "_template/aws/staging/terragrunt.hcl";
          "aws/staging/us-east-1/terragrunt.hcl";
          "aws/prod/us-east-1/terragrunt.hcl";
          "aws/prod/secrets-manager/us-east-1/terragrunt.hcl";
        ]
      in
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (R.String_map.of_list
                     [
                       ( "_template/*",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:(R.When_modified.make ~file_patterns:[] ())
                                      () );
                                ])
                           () );
                       ( "aws/**/secrets-manager/**/terragrunt.hcl",
                         R.Dirs.Dir.make
                           ~tags:[ "secrets" ]
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [
                                               CCResult.get_exn (R.File_pattern.make "${DIR}/*.hcl");
                                             ]
                                           ())
                                      () );
                                ])
                           () );
                       ( "aws/**/terragrunt.hcl",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [
                                               CCResult.get_exn (R.File_pattern.make "${DIR}/*.hcl");
                                             ]
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff =
        Terrat_change.Diff.
          [
            Add { filename = "aws/prod/us-east-1/terragrunt.hcl" };
            Add { filename = "aws/prod/secrets-manager/us-east-1/terragrunt.hcl" };
          ]
      in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes =
        CCList.filter
          (Terrat_change_match3.match_tag_query
             ~tag_query:(CCResult.get_exn (Terrat_tag_query.of_string "secrets")))
          (CCList.flatten (Terrat_change_match3.match_diff_list dirs diff))
      in
      assert (CCList.length changes = 1);
      CCList.iter
        (fun {
               Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; _ };
               when_modified;
               _;
             }
           ->
          let module Wm = Terrat_base_repo_config_v1.When_modified in
          match dir with
          | "aws/prod/secrets-manager/us-east-1" ->
              assert when_modified.Wm.autoplan;
              assert (not when_modified.Wm.autoapply)
          | _ -> assert false)
        changes)

let test_recursive_dirs_without_tags =
  Oth.test ~name:"Test Recursive Dirs Without Tags" (fun _ ->
      let file_list =
        [
          "_template/aws/terragrunt.hcl";
          "_template/aws/staging/terragrunt.hcl";
          "aws/staging/us-east-1/terragrunt.hcl";
          "aws/prod/us-east-1/terragrunt.hcl";
          "aws/prod/secrets-manager/us-east-1/terragrunt.hcl";
        ]
      in

      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (R.String_map.of_list
                     [
                       ( "_template/*",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:(R.When_modified.make ~file_patterns:[] ())
                                      () );
                                ])
                           () );
                       ( "aws/**/secrets-manager/**/terragrunt.hcl",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [
                                               CCResult.get_exn (R.File_pattern.make "${DIR}/*.hcl");
                                             ]
                                           ())
                                      () );
                                ])
                           () );
                       ( "aws/**/terragrunt.hcl",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [
                                               CCResult.get_exn (R.File_pattern.make "${DIR}/*.hcl");
                                             ]
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff =
        Terrat_change.Diff.
          [
            Add { filename = "aws/prod/us-east-1/terragrunt.hcl" };
            Add { filename = "aws/prod/secrets-manager/us-east-1/terragrunt.hcl" };
          ]
      in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 1);
      CCList.iter
        (fun {
               Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; _ };
               when_modified;
               _;
             }
           ->
          let module Wm = Terrat_base_repo_config_v1.When_modified in
          match dir with
          | "aws/prod/secrets-manager/us-east-1" | "aws/prod/us-east-1" ->
              assert when_modified.Wm.autoplan;
              assert (not when_modified.Wm.autoapply)
          | _ -> assert false)
        changes)

let test_bad_dir_config_iam =
  Oth.test ~name:"Test Bad Dir Config iam" (fun _ ->
      let repo_config =
        Terrat_base_repo_config_v1.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf"; "iam/foo.tf"; "ebl/ebl.tf"; "s3/s3.tf"; "s3/foo.tf"; "foo.tf" ]
          bad_dirs_config
      in
      let diff = Terrat_change.Diff.[ Add { filename = "iam/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      (* matches s3 and iam *)
      assert (CCList.length changes = 2))

let test_bad_dir_config_ec2 =
  Oth.test ~name:"Test Bad Dir Config ec2" (fun _ ->
      let repo_config =
        Terrat_base_repo_config_v1.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf"; "iam/foo.tf"; "ebl/ebl.tf"; "s3/s3.tf"; "s3/foo.tf"; "foo.tf" ]
          bad_dirs_config
      in
      let diff = Terrat_change.Diff.[ Add { filename = "ec2/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      (* matches s3 *)
      assert (CCList.length changes = 1))

let test_bad_dir_config_ec2_root_dir_change =
  Oth.test ~name:"Test Bad Dir Config ec2 root dir change" (fun _ ->
      let repo_config =
        Terrat_base_repo_config_v1.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf"; "iam/foo.tf"; "ebl/ebl.tf"; "s3/s3.tf"; "foo.tf" ]
          bad_dirs_config
      in
      let diff = Terrat_change.Diff.[ Add { filename = "foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      (* matches ., s3, and ec2 *)
      assert (CCList.length changes = 3))

let test_bad_dir_config_s3 =
  Oth.test ~name:"Test Bad Dir Config s3" (fun _ ->
      let repo_config =
        Terrat_base_repo_config_v1.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf"; "iam/foo.tf"; "ebl/ebl.tf"; "s3/s3.tf"; "s3/foo.tf"; "foo.tf" ]
          bad_dirs_config
      in
      let diff = Terrat_change.Diff.[ Add { filename = "s3/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 1))

let test_module_dir_with_root_dir =
  Oth.test ~name:"Test module dir with root dir" (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "foo.tf"; "module/foo/tf.tf" ]
          (R.of_view
             (R.View.make
                ~when_modified:
                  (R.When_modified.make
                     ~autoapply:true
                     ~autoplan:false
                     ~file_patterns:
                       [
                         CCResult.get_exn (R.File_pattern.make "${DIR}/*.tf");
                         CCResult.get_exn (R.File_pattern.make "${DIR}/*.tfvars");
                         CCResult.get_exn (R.File_pattern.make "${DIR}/*.json");
                       ]
                     ())
                ~dirs:
                  (R.String_map.of_list
                     [
                       ( "module",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:(R.When_modified.make ~file_patterns:[] ())
                                      () );
                                ])
                           () );
                       ( ".",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [
                                               CCResult.get_exn (R.File_pattern.make "./*.tf");
                                               CCResult.get_exn
                                                 (R.File_pattern.make "module/**/*.tf");
                                             ]
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "module/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 1))

let test_large_directory_count_unmatching_files =
  Oth.test ~name:"Test large directory count unmatching files" (fun _ ->
      let num_dirs = 4000 in
      let file_list =
        "ec2/ec2.tf"
        :: CCList.flat_map
             (fun i -> CCList.map (Printf.sprintf "other/%04d/bar_%d.txt" i) (CCList.range 0 10))
             (CCList.range 0 num_dirs)
      in
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive ~ctx ~index:Terrat_base_repo_config_v1.Index.empty ~file_list R.default
      in
      let diff = CCList.map (fun filename -> Terrat_change.Diff.(Change { filename })) file_list in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 1))

let test_large_directory_count_matching_files =
  Oth.test ~name:"Test large directory count matching files" (fun _ ->
      (* Number of operations = num_dirs * num_files.  Its not exactly that
         because each directory is not equal amounts of work. *)
      let num_dirs = 1000 in
      let num_files_per_dir = 10 in
      let file_list =
        "ec2/ec2.tf"
        :: CCList.flat_map
             (fun i ->
               CCList.map (Printf.sprintf "tf/%04d/bar_%d.tf" i) (CCList.range 1 num_files_per_dir))
             (CCList.range 1 num_dirs)
      in
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive ~ctx ~index:Terrat_base_repo_config_v1.Index.empty ~file_list R.default
      in
      let diff = CCList.map (fun filename -> Terrat_change.Diff.(Change { filename })) file_list in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 1 + num_dirs))

let test_large_directory_count_non_default_when_modified =
  Oth.test ~name:"Test large directory count non default when_modified" (fun _ ->
      (* Number of operations = num_dirs * num_files.  Its not exactly that
         because each directory is not equal amounts of work. *)
      let num_dirs = 1000 in
      let num_files_per_dir = 10 in
      let file_list =
        "ec2/ec2.tf"
        :: CCList.flat_map
             (fun i ->
               CCList.map (Printf.sprintf "tf/%04d/bar_%d.tf" i) (CCList.range 1 num_files_per_dir))
             (CCList.range 1 num_dirs)
        @ [ "foo/bar.txt" ]
      in

      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~when_modified:
                  (R.When_modified.make
                     ~file_patterns:
                       [
                         CCResult.get_exn (R.File_pattern.make "**/*.bar");
                         CCResult.get_exn (R.File_pattern.make "foo/*.txt");
                       ]
                     ())
                ()))
      in
      let diff = CCList.map (fun filename -> Terrat_change.Diff.(Change { filename })) file_list in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 2 + num_dirs))

let test_not_match =
  Oth.test ~name:"Test not match" (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf" ]
          (R.of_view
             (R.View.make
                ~when_modified:
                  (R.When_modified.make
                     ~file_patterns:
                       [
                         CCResult.get_exn (R.File_pattern.make "**/*.tf");
                         CCResult.get_exn (R.File_pattern.make "!ec2/**/*.tf");
                       ]
                     ())
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 0))

let test_not_match_multiple =
  Oth.test ~name:"Test not match multiple" (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf" ]
          (R.of_view
             (R.View.make
                ~when_modified:
                  (R.When_modified.make
                     ~file_patterns:
                       [
                         CCResult.get_exn (R.File_pattern.make "**/*.tf");
                         CCResult.get_exn (R.File_pattern.make "!ec2/**/*.tf");
                         CCResult.get_exn (R.File_pattern.make "!foo/*.tf");
                       ]
                     ())
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 0))

let test_relative_path_file_pattern =
  Oth.test ~name:"Test relative path file pattern" (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "d/bar/foo/t.tf"; "d/bar/baz/t.tf" ]
          (R.of_view
             (R.View.make
                ~dirs:
                  (R.String_map.of_list
                     [
                       ( "d/bar/foo",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:(R.When_modified.make ~file_patterns:[] ())
                                      () );
                                ])
                           () );
                       ( "d/**/*.tf",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [
                                               CCResult.get_exn
                                                 (R.File_pattern.make "${DIR}/../foo/*.tf");
                                               CCResult.get_exn (R.File_pattern.make "${DIR}/*.tf");
                                             ]
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "d/bar/foo/t.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 1))

let test_relative_path_file_pattern_multiple_dots =
  Oth.test ~name:"Test relative path file pattern multiple dots" (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "d/bar/foo/t.tf"; "d/bar/envs/baz/t.tf" ]
          (R.of_view
             (R.View.make
                ~dirs:
                  (R.String_map.of_list
                     [
                       ( "d/bar/foo",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:(R.When_modified.make ~file_patterns:[] ())
                                      () );
                                ])
                           () );
                       ( "d/**/*.tf",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [
                                               CCResult.get_exn
                                                 (R.File_pattern.make "${DIR}/../../foo/*.tf");
                                               CCResult.get_exn (R.File_pattern.make "${DIR}/*.tf");
                                             ]
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "d/bar/foo/t.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 1))

let test_index_basic =
  Oth.test ~name:"Test basic index" (fun _ ->
      let module Idx = Terrat_base_repo_config_v1.Index in
      let index = Idx.make ~symlinks:[] [ ("tf", Idx.Dep.[ Module "../modules/foo" ]) ] in
      let file_list = [ "modules/foo/main.tf"; "tf/main.tf" ] in
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive ~ctx ~index ~file_list R.default
      in
      let dirs = CCResult.get_exn (Terrat_change_match3.synthesize_config ~index repo_config) in
      let diff = Terrat_change.Diff.[ Add { filename = "modules/foo/main.tf" } ] in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 1);
      let dirspace = (CCList.hd changes).Terrat_change_match3.Dirspace_config.dirspace in
      assert (
        Terrat_change.Dirspace.equal
          dirspace
          Terrat_change.Dirspace.{ dir = "tf"; workspace = "default" }))

let test_index_with_dirs_section =
  Oth.test ~name:"Test index with dirs section" (fun _ ->
      let module Idx = Terrat_base_repo_config_v1.Index in
      let index = Idx.make ~symlinks:[] [ ("tf", Idx.Dep.[ Module "../modules/foo" ]) ] in
      let file_list = [ "modules/foo/main.tf"; "tf/main.tf" ] in
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive
          ~ctx
          ~index
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:(R.String_map.of_list [ ("tf", R.Dirs.Dir.make ~tags:[ "tf" ] ()) ])
                ()))
      in
      let dirs = CCResult.get_exn (Terrat_change_match3.synthesize_config ~index repo_config) in
      let diff = Terrat_change.Diff.[ Add { filename = "modules/foo/main.tf" } ] in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 1);
      let dirspace = (CCList.hd changes).Terrat_change_match3.Dirspace_config.dirspace in
      assert (
        Terrat_change.Dirspace.equal
          dirspace
          Terrat_change.Dirspace.{ dir = "tf"; workspace = "default" }))

let test_index_module_in_same_dir =
  Oth.test ~name:"Test basic index" (fun _ ->
      let module Idx = Terrat_base_repo_config_v1.Index in
      let index =
        Idx.make
          ~symlinks:[]
          [ ("tf", Idx.Dep.[ Module "./modules/foo" ]); ("tf/modules/foo", Idx.Dep.[]) ]
      in
      let file_list = [ "tf/modules/foo/main.tf"; "tf/main.tf" ] in
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive ~ctx ~index ~file_list R.default
      in
      let dirs = CCResult.get_exn (Terrat_change_match3.synthesize_config ~index repo_config) in
      let diff = Terrat_change.Diff.[ Add { filename = "tf/modules/foo/main.tf" } ] in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 1);
      let dirspace = (CCList.hd changes).Terrat_change_match3.Dirspace_config.dirspace in
      assert (
        Terrat_change.Dirspace.equal
          dirspace
          Terrat_change.Dirspace.{ dir = "tf"; workspace = "default" }))

let test_index_symlinks =
  Oth.test ~name:"Test basic symlinks" (fun _ ->
      let module Idx = Terrat_base_repo_config_v1.Index in
      let index =
        Idx.make
          ~symlinks:[ ("tf/modules/foo", "modules/foo") ]
          [ ("tf", Idx.Dep.[ Module "./modules/foo" ]) ]
      in
      let file_list = [ "modules/foo/main.tf"; "tf/main.tf" ] in
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive ~ctx ~index ~file_list R.default
      in
      let dirs = CCResult.get_exn (Terrat_change_match3.synthesize_config ~index repo_config) in
      let diff = Terrat_change.Diff.[ Add { filename = "modules/foo/main.tf" } ] in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 1);
      let dirspace = (CCList.hd changes).Terrat_change_match3.Dirspace_config.dirspace in
      assert (
        Terrat_change.Dirspace.equal
          dirspace
          Terrat_change.Dirspace.{ dir = "tf"; workspace = "default" }))

let test_index_symlinks_dir_config =
  Oth.test ~name:"Test basic symlinks with dir config" (fun _ ->
      let module Idx = Terrat_base_repo_config_v1.Index in
      let index = Idx.make ~symlinks:[ ("tf/main.tf", "null/main.tf") ] [] in
      let file_list = [ "tf/main.tf"; "null/main.tf" ] in
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        R.derive
          ~ctx
          ~index
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (R.String_map.of_list
                     [
                       ( "null",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:(R.When_modified.make ~file_patterns:[] ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let dirs = CCResult.get_exn (Terrat_change_match3.synthesize_config ~index repo_config) in
      let diff = Terrat_change.Diff.[ Change { filename = "null/main.tf" } ] in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      assert (CCList.length changes = 1);
      let dirspace = (CCList.hd changes).Terrat_change_match3.Dirspace_config.dirspace in
      assert (
        Terrat_change.Dirspace.equal
          dirspace
          Terrat_change.Dirspace.{ dir = "tf"; workspace = "default" }))

let test_depends_on =
  Oth.test ~name:"Simple depends_on" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let file_list = [ "base/main.tf"; "database/main.tf" ] in
      let repo_config =
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (R.String_map.of_list
                     [
                       ( "database",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:
                                             (CCResult.get_exn
                                                (Terrat_tag_query.of_string "dir:base"))
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "base/main.tf" } ] in
      let config =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = Terrat_change_match3.match_diff_list config diff in
      assert (CCList.length changes = 2))

let test_depends_on_multiple_depends =
  Oth.test ~name:"Simple depends_on multiple depends" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let file_list = [ "base/main.tf"; "database1/main.tf"; "database2/main.tf" ] in
      let repo_config =
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (R.String_map.of_list
                     [
                       ( "database1",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:
                                             (CCResult.get_exn
                                                (Terrat_tag_query.of_string "dir:base"))
                                           ())
                                      () );
                                ])
                           () );
                       ( "database2",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:
                                             (CCResult.get_exn
                                                (Terrat_tag_query.of_string "dir:base"))
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "base/main.tf" } ] in
      let config =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = Terrat_change_match3.match_diff_list config diff in
      assert (CCList.length changes = 2);
      match changes with
      | [ base; databases ] ->
          assert (CCList.length base = 1);
          assert (CCList.length databases = 2)
      | _ -> assert false)

let test_depends_on_multiple_depends_2 =
  Oth.test ~name:"Simple depends_on multiple depends 2" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let file_list =
        [ "base/main.tf"; "database1/main.tf"; "database2/main.tf"; "webservice/main.tf" ]
      in
      let repo_config =
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (R.String_map.of_list
                     [
                       ( "database1",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:
                                             (CCResult.get_exn
                                                (Terrat_tag_query.of_string "dir:base"))
                                           ())
                                      () );
                                ])
                           () );
                       ( "database2",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:
                                             (CCResult.get_exn
                                                (Terrat_tag_query.of_string "dir:base"))
                                           ())
                                      () );
                                ])
                           () );
                       ( "webservice",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:
                                             (CCResult.get_exn
                                                (Terrat_tag_query.of_string
                                                   "dir:database1 or dir:database2"))
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "base/main.tf" } ] in
      let config =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = Terrat_change_match3.match_diff_list config diff in
      assert (CCList.length changes = 3);
      match changes with
      | [ base; databases; webservice ] ->
          assert (CCList.length base = 1);
          assert (CCList.length databases = 2);
          assert (CCList.length webservice = 1)
      | _ -> assert false)

let test_depends_on_multiple_depends_disjoint =
  Oth.test ~name:"Simple depends_on multiple depends disjoint" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let file_list =
        [
          "base/main.tf";
          "database1/main.tf";
          "database2/main.tf";
          "webservice1/main.tf";
          "webservice2/main.tf";
        ]
      in
      let repo_config =
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (R.String_map.of_list
                     [
                       ( "database1",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:
                                             (CCResult.get_exn
                                                (Terrat_tag_query.of_string "dir:base"))
                                           ())
                                      () );
                                ])
                           () );
                       ( "database2",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:
                                             (CCResult.get_exn
                                                (Terrat_tag_query.of_string "dir:base"))
                                           ())
                                      () );
                                ])
                           () );
                       ( "webservice1",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:
                                             (CCResult.get_exn
                                                (Terrat_tag_query.of_string "dir:database1"))
                                           ())
                                      () );
                                ])
                           () );
                       ( "webservice2",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:
                                             (CCResult.get_exn
                                                (Terrat_tag_query.of_string "dir:database2"))
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "base/main.tf" } ] in
      let config =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = Terrat_change_match3.match_diff_list config diff in
      assert (CCList.length changes = 3);
      match changes with
      | [ base; databases; webservices ] ->
          assert (CCList.length base = 1);
          assert (CCList.length databases = 2);
          assert (CCList.length webservices = 2)
      | _ -> assert false)

let test_depends_on_cycle =
  Oth.test ~name:"depends_on cycle error" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let file_list = [ "base/main.tf"; "database/main.tf" ] in
      let repo_config =
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (R.String_map.of_list
                     [
                       ( "base",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:
                                             (CCResult.get_exn
                                                (Terrat_tag_query.of_string "dir:database"))
                                           ())
                                      () );
                                ])
                           () );
                       ( "database",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:
                                             (CCResult.get_exn
                                                (Terrat_tag_query.of_string "dir:base"))
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      match
        Terrat_change_match3.synthesize_config
          ~index:Terrat_base_repo_config_v1.Index.empty
          repo_config
      with
      | Ok _ -> assert false
      | Error (`Depends_on_cycle_err _) -> ()
      | Error _ -> assert false)

let test_depends_on_relative_dir =
  Oth.test ~name:"depends_on relative dir" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let file_list =
        [
          "projects/proj1/base/main.tf";
          "projects/proj1/database/main.tf";
          "projects/proj2/base/main.tf";
          "projects/proj2/database/main.tf";
        ]
      in
      let repo_config =
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (R.String_map.of_list
                     [
                       ( "projects/**/database/*.tf",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:
                                             (CCResult.get_exn
                                                (Terrat_tag_query.of_string "relative_dir:../base"))
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "projects/proj1/base/main.tf" } ] in
      let config =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = Terrat_change_match3.match_diff_list config diff in
      assert (CCList.length changes = 2);
      let dirspace_eq ds { Terrat_change_match3.Dirspace_config.dirspace; _ } =
        Terrat_dirspace.equal ds dirspace
      in
      let changes = CCList.flatten changes in
      assert (
        CCOption.is_some
          (CCList.find_opt
             (dirspace_eq { Terrat_dirspace.dir = "projects/proj1/base"; workspace = "default" })
             changes));
      assert (
        CCOption.is_some
          (CCList.find_opt
             (dirspace_eq
                { Terrat_dirspace.dir = "projects/proj1/database"; workspace = "default" })
             changes)))

let test_files_in_same_dir_match_multiple_dirs =
  Oth.test ~name:"files_in_same_dir_match_multiple_dirs" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let file_list = [ "projects/dir1/file1"; "projects/dir1/file2" ] in
      let repo_config =
        R.derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (R.String_map.of_list
                     [
                       ( "projects/**",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:(R.When_modified.make ~file_patterns:[] ())
                                      () );
                                ])
                           () );
                       ( "projects/**/file1",
                         R.Dirs.Dir.make
                           ~tags:[ "dir1" ]
                           ~workspaces:
                             (R.String_map.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [ CCResult.get_exn (R.File_pattern.make "${DIR}/*") ]
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff =
        Terrat_change.Diff.
          [ Add { filename = "projects/dir1/file1" }; Add { filename = "projects/dir1/file2" } ]
      in
      let config =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list config diff) in
      assert (CCList.length changes = 1);
      match changes with
      | [ { Terrat_change_match3.Dirspace_config.tags; _ } ] ->
          assert (Terrat_tag_set.mem "dir1" tags)
      | _ -> assert false)

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
      test_bad_dir_config_iam;
      test_bad_dir_config_ec2;
      test_bad_dir_config_ec2_root_dir_change;
      test_bad_dir_config_s3;
      test_module_dir_with_root_dir;
      test_large_directory_count_unmatching_files;
      test_large_directory_count_matching_files;
      test_large_directory_count_non_default_when_modified;
      test_not_match;
      test_not_match_multiple;
      test_relative_path_file_pattern;
      test_relative_path_file_pattern_multiple_dots;
      test_index_basic;
      test_index_with_dirs_section;
      test_index_module_in_same_dir;
      test_index_symlinks;
      test_index_symlinks_dir_config;
      test_depends_on;
      test_depends_on_multiple_depends;
      test_depends_on_multiple_depends_2;
      test_depends_on_multiple_depends_disjoint;
      test_depends_on_cycle;
      test_depends_on_relative_dir;
      test_files_in_same_dir_match_multiple_dirs;
    ]

let () =
  Random.self_init ();
  Oth.run test
