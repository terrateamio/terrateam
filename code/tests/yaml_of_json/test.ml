(* let show_err = [%show: (string, string) result] *)

let test_valid =
  Oth.test ~name:"valid" (fun _ ->
      let json = {|{"type":"run"}|} in
      assert (Yaml_of_json.yaml_of_json json = Ok "type: run\n"))

let test_invalid =
  Oth.test ~name:"invalid" (fun _ ->
      let json = {|"type": "foo|} in
      assert (
        Yaml_of_json.yaml_of_json json
        = Error "JSON parsing error: trailing characters at line 1 column 7"))

let test = Oth.parallel [ test_valid; test_invalid ]

let () =
  Random.self_init ();
  Oth.run test
