let test_adhoc_to_yojson =
  Oth.test ~name:"Adhoc to_yojson produces correct JSON" (fun _ ->
      let adhoc = Terrat_job_type_kind_adhoc.make ~type_:"adhoc" in
      let json = Terrat_job_type_kind_adhoc.to_yojson adhoc in
      let expected = `Assoc [ ("type", `String "adhoc") ] in
      assert (Yojson.Safe.equal json expected))

let test_adhoc_of_yojson_valid =
  Oth.test ~name:"Adhoc of_yojson parses valid JSON" (fun _ ->
      let json = `Assoc [ ("type", `String "adhoc") ] in
      match Terrat_job_type_kind_adhoc.of_yojson json with
      | Ok adhoc ->
          let module A = Terrat_job_type_kind_adhoc in
          assert (A.equal adhoc (A.make ~type_:"adhoc"))
      | Error err -> failwith ("Expected Ok, got Error: " ^ err))

let test_adhoc_of_yojson_invalid =
  Oth.test ~name:"Adhoc of_yojson rejects invalid type" (fun _ ->
      let json = `Assoc [ ("type", `String "invalid") ] in
      match Terrat_job_type_kind_adhoc.of_yojson json with
      | Ok _ -> failwith "Expected Error, got Ok"
      | Error _ -> ())

let test_kind_adhoc_to_yojson =
  Oth.test ~name:"Kind_adhoc to_yojson produces correct JSON" (fun _ ->
      let module K = Terrat_job_type_kind in
      let adhoc = Terrat_job_type_kind_adhoc.make ~type_:"adhoc" in
      let json = K.to_yojson (K.Kind_adhoc adhoc) in
      let expected = `Assoc [ ("type", `String "adhoc") ] in
      assert (Yojson.Safe.equal json expected))

let test_kind_adhoc_of_yojson =
  Oth.test ~name:"Kind of_yojson parses Kind_adhoc from JSON" (fun _ ->
      let module K = Terrat_job_type_kind in
      let json = `Assoc [ ("type", `String "adhoc") ] in
      match K.of_yojson json with
      | Ok (K.Kind_adhoc adhoc) ->
          let module A = Terrat_job_type_kind_adhoc in
          assert (A.equal adhoc (A.make ~type_:"adhoc"))
      | Ok (K.Kind_drift _) -> failwith "Expected Kind_adhoc, got Kind_drift"
      | Error err -> failwith ("Expected Ok, got Error: " ^ err))

let test_kind_drift_of_yojson =
  Oth.test ~name:"Kind of_yojson still parses Kind_drift (no regression)" (fun _ ->
      let module K = Terrat_job_type_kind in
      let json = `Assoc [ ("type", `String "drift") ] in
      match K.of_yojson json with
      | Ok (K.Kind_drift _) -> ()
      | Ok (K.Kind_adhoc _) -> failwith "Expected Kind_drift, got Kind_adhoc"
      | Error err -> failwith ("Expected Ok, got Error: " ^ err))

let test =
  Oth.serial
    [
      test_adhoc_to_yojson;
      test_adhoc_of_yojson_valid;
      test_adhoc_of_yojson_invalid;
      test_kind_adhoc_to_yojson;
      test_kind_adhoc_of_yojson;
      test_kind_drift_of_yojson;
    ]

let () = Oth.run test
