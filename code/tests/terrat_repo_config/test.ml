(* Round-trip and validation tests for Engine_stategraph at the schema layer. *)

module E = Terrat_repo_config.Engine
module Sg = Terrat_repo_config.Engine_stategraph

let test_stategraph_minimal_round_trip =
  Oth.test ~name:"Engine_stategraph: minimal round-trip" (fun _ ->
      let json = `Assoc [ ("name", `String "stategraph") ] in
      match Sg.of_yojson json with
      | Ok t ->
          assert (t.Sg.name = `Stategraph);
          assert (t.Sg.version = None);
          assert (Sg.to_yojson t = `Assoc [ ("name", `String "stategraph") ])
      | Error msg -> failwith msg)

let test_stategraph_with_version_round_trip =
  Oth.test ~name:"Engine_stategraph: with version round-trip" (fun _ ->
      let json = `Assoc [ ("name", `String "stategraph"); ("version", `String "1.2.1") ] in
      match Sg.of_yojson json with
      | Ok t -> (
          assert (t.Sg.name = `Stategraph);
          assert (t.Sg.version = Some "1.2.1");
          let round_tripped = Sg.to_yojson t in
          match Sg.of_yojson round_tripped with
          | Ok t' -> assert (t'.Sg.version = Some "1.2.1")
          | Error msg -> failwith msg)
      | Error msg -> failwith msg)

let test_stategraph_rejects_extra_field =
  Oth.test ~name:"Engine_stategraph: extra field rejected (strict=true)" (fun _ ->
      let json =
        `Assoc
          [
            ("name", `String "stategraph");
            ("version", `String "1.2.1");
            ("not_a_real_field", `String "value");
          ]
      in
      match Sg.of_yojson json with
      | Ok _ -> failwith "Expected strict=true to reject extra field, but it was accepted"
      | Error _ -> ())

let test_stategraph_rejects_wrong_name =
  Oth.test ~name:"Engine_stategraph: wrong const name rejected" (fun _ ->
      let json = `Assoc [ ("name", `String "not-stategraph") ] in
      match Sg.of_yojson json with
      | Ok _ -> failwith "Expected mismatched const to reject, but it was accepted"
      | Error _ -> ())

let test_engine_chain_picks_stategraph =
  Oth.test ~name:"Engine: of_yojson chain dispatches to Engine_stategraph" (fun _ ->
      let json = `Assoc [ ("name", `String "stategraph"); ("version", `String "1.2.1") ] in
      match E.of_yojson json with
      | Ok (E.Engine_stategraph t) ->
          assert (t.Sg.name = `Stategraph);
          assert (t.Sg.version = Some "1.2.1")
      | Ok _ -> failwith "Expected Engine_stategraph variant, got a different engine"
      | Error msg -> failwith msg)

let test_engine_chain_to_yojson_dispatches =
  Oth.test ~name:"Engine: to_yojson on Engine_stategraph emits stategraph JSON" (fun _ ->
      let t = Sg.make ~name:`Stategraph ~version:(Some "1.2.1") () in
      let json = E.to_yojson (E.Engine_stategraph t) in
      assert (json = `Assoc [ ("name", `String "stategraph"); ("version", `String "1.2.1") ]))

let test_stategraph_with_tf_fields_round_trip =
  Oth.test ~name:"Engine_stategraph: tf_cmd/tf_version/override_tf_cmd round-trip" (fun _ ->
      let json =
        `Assoc
          [
            ("name", `String "stategraph");
            ("override_tf_cmd", `String "tofu");
            ("tf_cmd", `String "tofu");
            ("tf_version", `String "1.7.0");
          ]
      in
      match Sg.of_yojson json with
      | Ok t ->
          assert (t.Sg.tf_cmd = Some "tofu");
          assert (t.Sg.tf_version = Some "1.7.0");
          assert (t.Sg.override_tf_cmd = Some "tofu");
          assert (Sg.to_yojson t = json)
      | Error msg -> failwith msg)

let test_engine_chain_unknown_falls_to_other =
  Oth.test ~name:"Engine: unknown name falls through to Engine_other" (fun _ ->
      let json = `Assoc [ ("name", `String "definitely-not-an-engine") ] in
      match E.of_yojson json with
      | Ok (E.Engine_other _) -> ()
      | Ok _ -> failwith "Expected Engine_other fallback, got a different engine"
      | Error _ ->
          failwith "Expected Engine_other to accept unknown engine names; got Error instead")

module Ns = Terrat_repo_config.Notifications_summary

let test_notifications_summary_pull_request_round_trip =
  Oth.test ~name:"Notifications_summary: mode pull_request round-trip" (fun _ ->
      let json = `Assoc [ ("enabled", `Bool true); ("mode", `String "pull_request") ] in
      match Ns.of_yojson json with
      | Ok t -> (
          assert (t.Ns.enabled = true);
          assert (t.Ns.mode = `Pull_request);
          let round_tripped = Ns.to_yojson t in
          match Ns.of_yojson round_tripped with
          | Ok t' -> assert (t'.Ns.mode = `Pull_request)
          | Error msg -> failwith msg)
      | Error msg -> failwith msg)

let test_notifications_summary_header_round_trip =
  Oth.test ~name:"Notifications_summary: mode header round-trip" (fun _ ->
      let json = `Assoc [ ("enabled", `Bool true); ("mode", `String "header") ] in
      match Ns.of_yojson json with
      | Ok t -> (
          assert (t.Ns.mode = `Header);
          let round_tripped = Ns.to_yojson t in
          match Ns.of_yojson round_tripped with
          | Ok t' -> assert (t'.Ns.mode = `Header)
          | Error msg -> failwith msg)
      | Error msg -> failwith msg)

let test_notifications_summary_mode_default =
  Oth.test ~name:"Notifications_summary: mode omitted defaults to header" (fun _ ->
      let json = `Assoc [ ("enabled", `Bool true) ] in
      match Ns.of_yojson json with
      | Ok t ->
          assert (t.Ns.enabled = true);
          assert (t.Ns.mode = `Header)
      | Error msg -> failwith msg)

let test_notifications_summary_rejects_unknown_mode =
  Oth.test ~name:"Notifications_summary: unknown mode rejected" (fun _ ->
      let json = `Assoc [ ("enabled", `Bool true); ("mode", `String "sidebar") ] in
      match Ns.of_yojson json with
      | Ok _ -> failwith "Expected unknown mode to be rejected, but it was accepted"
      | Error _ -> ())

let test =
  Oth.parallel
    [
      test_stategraph_minimal_round_trip;
      test_stategraph_with_version_round_trip;
      test_stategraph_rejects_extra_field;
      test_stategraph_rejects_wrong_name;
      test_engine_chain_picks_stategraph;
      test_engine_chain_to_yojson_dispatches;
      test_stategraph_with_tf_fields_round_trip;
      test_engine_chain_unknown_falls_to_other;
      test_notifications_summary_pull_request_round_trip;
      test_notifications_summary_header_round_trip;
      test_notifications_summary_mode_default;
      test_notifications_summary_rejects_unknown_mode;
    ]

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ test
