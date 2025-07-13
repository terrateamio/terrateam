let test_valid =
  Oth.test ~name:"valid" (fun _ ->
      let yaml = {|type: run|} in
      assert (Json_of_yaml.json_of_yaml yaml = Ok {|{"type":"run"}|}))

let test_invalid =
  Oth.test ~name:"invalid" (fun _ ->
      let yaml = {|type: [foo|} in
      assert (
        Json_of_yaml.json_of_yaml yaml
        = Error
            "YAML parsing error: did not find expected ',' or ']' at line 2 column 1, while \
             parsing a flow sequence at line 1 column 7"))

let test = Oth.parallel [ test_valid; test_invalid ]

let () =
  Random.self_init ();
  Oth.run test
