module V1 = Terrat_repo_config.Version_1
module R = Terrat_base_repo_config_v1

let file_patterns_equal fp s =
  CCList.equal
    CCString.equal
    (CCList.sort CCString.compare (CCList.map R.File_pattern.file_pattern fp))
    (CCList.sort CCString.compare s)

let test_empty =
  Oth.test ~name:"Test empty" (fun _ ->
      let version_1 = CCResult.get_exn (V1.of_yojson (`Assoc [])) in
      let repo_config = R.of_version_1 version_1 in
      assert (CCResult.is_ok repo_config))

let test_complex =
  Oth.test ~name:"Test complex" (fun _ ->
      let version_1 =
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
                                   ( "file_patterns",
                                     `List [ `String "ebl/*.tf"; `String "ebl_modules" ] );
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
                       ( "module",
                         `Assoc [ ("when_modified", `Assoc [ ("file_patterns", `List []) ]) ] );
                       ( "null_file_patterns",
                         `Assoc [ ("when_modified", `Assoc [ ("file_patterns", `Null) ]) ] );
                     ] );
               ]))
      in
      let repo_config = R.of_version_1 version_1 in
      assert (CCResult.is_ok repo_config);
      let repo_config = CCResult.get_exn repo_config in
      assert (not repo_config.R.when_modified.R.When_modified.autoplan);
      assert repo_config.R.when_modified.R.When_modified.autoapply;
      assert (
        file_patterns_equal
          repo_config.R.when_modified.R.When_modified.file_patterns
          [ "${DIR}/*.tf"; "${DIR}/*.tfvars"; "${DIR}/*.json" ]);
      let dir = R.String_map.find "iam" repo_config.R.dirs in
      assert (not dir.R.Dirs.Dir.when_modified.R.When_modified.autoplan);
      assert (
        file_patterns_equal
          dir.R.Dirs.Dir.when_modified.R.When_modified.file_patterns
          [ "iam/*.tf" ]);
      let dir = R.String_map.find "ebl" repo_config.R.dirs in
      assert dir.R.Dirs.Dir.when_modified.R.When_modified.autoapply;
      assert (
        file_patterns_equal
          dir.R.Dirs.Dir.when_modified.R.When_modified.file_patterns
          [ "ebl/*.tf"; "ebl_modules" ]);
      let dir = R.String_map.find "ec2" repo_config.R.dirs in
      assert dir.R.Dirs.Dir.when_modified.R.When_modified.autoapply;
      assert (
        file_patterns_equal
          dir.R.Dirs.Dir.when_modified.R.When_modified.file_patterns
          [ "iam/*.tf" ]))

let test = Oth.parallel [ test_empty; test_complex ]

let () =
  Random.self_init ();
  Oth.run test
