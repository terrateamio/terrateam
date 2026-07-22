(* Round-trip tests for the new Engine.Stategraph variant in v1 base config.
   Drives through the public of_version_1_json / to_version_1 surface so we
   exercise the new pattern-match arms in of_version_1_engine and
   to_version_1_engine end to end. *)

module V1 = Terrat_base_repo_config_v1
module Repo = Terrat_repo_config
module Sg_schema = Terrat_repo_config.Engine_stategraph

let pp_engine = function
  | V1.Engine.Stategraph _ -> "Stategraph"
  | V1.Engine.Cdktf _ -> "Cdktf"
  | V1.Engine.Custom _ -> "Custom"
  | V1.Engine.Fly _ -> "Fly"
  | V1.Engine.Opentofu _ -> "Opentofu"
  | V1.Engine.Other _ -> "Other"
  | V1.Engine.Pulumi -> "Pulumi"
  | V1.Engine.Terraform _ -> "Terraform"
  | V1.Engine.Terragrunt _ -> "Terragrunt"

let test_of_version_1_json_minimal =
  Oth.test ~name:"of_version_1_json: stategraph engine (no version)" (fun _ ->
      let json = `Assoc [ ("engine", `Assoc [ ("name", `String "stategraph") ]) ] in
      match V1.of_version_1_json json with
      | Ok cfg -> (
          match V1.engine cfg with
          | V1.Engine.Stategraph { V1.Engine.Stategraph.version = None } -> ()
          | other ->
              failwith
                (Printf.sprintf
                   "Expected Engine.Stategraph with version=None, got %s"
                   (pp_engine other)))
      | Error _ -> failwith "of_version_1_json failed on minimal stategraph engine config")

let test_of_version_1_json_with_version =
  Oth.test ~name:"of_version_1_json: stategraph engine (with version)" (fun _ ->
      let json =
        `Assoc
          [ ("engine", `Assoc [ ("name", `String "stategraph"); ("version", `String "1.2.1") ]) ]
      in
      match V1.of_version_1_json json with
      | Ok cfg -> (
          match V1.engine cfg with
          | V1.Engine.Stategraph { V1.Engine.Stategraph.version = Some "1.2.1" } -> ()
          | other ->
              failwith
                (Printf.sprintf
                   "Expected Engine.Stategraph with version=Some 1.2.1, got %s"
                   (pp_engine other)))
      | Error _ -> failwith "of_version_1_json failed on stategraph engine with version")

let test_to_version_1_round_trip =
  Oth.test ~name:"to_version_1: stategraph engine round-trips through Version_1" (fun _ ->
      let json =
        `Assoc
          [ ("engine", `Assoc [ ("name", `String "stategraph"); ("version", `String "1.2.1") ]) ]
      in
      match V1.of_version_1_json json with
      | Ok cfg -> (
          let v1 = V1.to_version_1 cfg in
          match v1.Repo.Version_1.engine with
          | Some
              (Repo.Engine.Engine_stategraph
                 { Sg_schema.name = `Stategraph; version = Some "1.2.1" }) -> ()
          | _ -> failwith "Round-trip to Version_1 did not produce Engine_stategraph")
      | Error _ -> failwith "of_version_1_json failed in round-trip setup")

let test_notifications_summary_mode_pull_request =
  Oth.test ~name:"of_version_1_json: notifications summary mode pull_request" (fun _ ->
      let module Sum = V1.Notifications.Summary in
      let json =
        `Assoc
          [
            ( "notifications",
              `Assoc
                [
                  ("summary", `Assoc [ ("enabled", `Bool true); ("mode", `String "pull_request") ]);
                ] );
          ]
      in
      match V1.of_version_1_json json with
      | Ok cfg -> (
          let { V1.Notifications.summary; _ } = V1.notifications cfg in
          match summary with
          | { Sum.enabled = true; mode = Sum.Mode.Pull_request } -> ()
          | _ -> failwith "Expected summary enabled=true with mode=Pull_request")
      | Error _ -> failwith "of_version_1_json failed on notifications summary pull_request config")

let test_notifications_summary_mode_default =
  Oth.test ~name:"of_version_1_json: notifications summary mode defaults to header" (fun _ ->
      let module Sum = V1.Notifications.Summary in
      let json =
        `Assoc [ ("notifications", `Assoc [ ("summary", `Assoc [ ("enabled", `Bool true) ]) ]) ]
      in
      match V1.of_version_1_json json with
      | Ok cfg -> (
          let { V1.Notifications.summary; _ } = V1.notifications cfg in
          match summary with
          | { Sum.enabled = true; mode = Sum.Mode.Header } -> ()
          | _ -> failwith "Expected summary enabled=true with default mode=Header")
      | Error _ -> failwith "of_version_1_json failed on notifications summary default mode config")

let test_notifications_summary_mode_round_trip =
  Oth.test ~name:"to_version_1: notifications summary mode round-trips" (fun _ ->
      let module Sn = Repo.Notifications_summary in
      let round_trip mode_str expected =
        let json =
          `Assoc
            [
              ( "notifications",
                `Assoc
                  [ ("summary", `Assoc [ ("enabled", `Bool true); ("mode", `String mode_str) ]) ] );
            ]
        in
        match V1.of_version_1_json json with
        | Ok cfg -> (
            let v1 = V1.to_version_1 cfg in
            match v1.Repo.Version_1.notifications with
            | Some { Repo.Notifications.summary = Some { Sn.enabled = true; mode }; _ } ->
                if mode <> expected then
                  failwith
                    (Printf.sprintf "Round-trip of mode %s produced a different mode" mode_str)
            | _ -> failwith "Round-trip to Version_1 did not produce a notifications summary")
        | Error _ -> failwith "of_version_1_json failed in notifications summary round-trip setup"
      in
      round_trip "pull_request" `Pull_request;
      round_trip "header" `Header)

let test =
  Oth.parallel
    [
      test_of_version_1_json_minimal;
      test_of_version_1_json_with_version;
      test_to_version_1_round_trip;
      test_notifications_summary_mode_pull_request;
      test_notifications_summary_mode_default;
      test_notifications_summary_mode_round_trip;
    ]

let () =
  Random.self_init ();
  Oth.run test
