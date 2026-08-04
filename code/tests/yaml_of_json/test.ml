(* let show_err = [%show: (string, string) result] *)

let test_valid =
  Oth.test ~name:"valid" (fun _ ->
      let json = {|{"type":"run"}|} in
      Oth.Assert.true_
        "Yaml_of_json.yaml_of_json json = Ok \"type: run\\n\""
        (Yaml_of_json.yaml_of_json json = Ok "type: run\n"))

let test_invalid =
  Oth.test ~name:"invalid" (fun _ ->
      let json = {|"type": "foo|} in
      Oth.Assert.true_
        "Yaml_of_json.yaml_of_json json = Error \"JSON parsing error: trailing characters ...\""
        (Yaml_of_json.yaml_of_json json
        = Error "JSON parsing error: trailing characters at line 1 column 7"))

let test = Oth.parallel [ test_valid; test_invalid ]

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
