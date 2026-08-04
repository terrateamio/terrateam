(* let show_errors = [%show: Jsonschema_check.Validation_err.t list] *)

let test_valid =
  Oth.test ~name:"valid" (fun _ ->
      let schema = {|{"type": "object", "properties": {"name": {"type": "string"}}}|} in
      let valid_json = {|{"name": "John"}|} in
      Oth.Assert.true_
        "Jsonschema_check.validate_json_schema ~schema valid_json = Ok ()"
        (Jsonschema_check.validate_json_schema ~schema valid_json = Ok ()))

let test_invalid =
  Oth.test ~name:"invalid" (fun _ ->
      let schema = {|{"type": "object", "properties": {"name": {"type": "string"}}}|} in
      let valid_json = {|{"name": 123}|} in
      match Jsonschema_check.validate_json_schema ~schema valid_json with
      | Ok () -> Oth.Assert.false_ "invalid: unexpected value"
      | Error errors ->
          Oth.Assert.true_
            "errors = [ { Jsonschema_check.Validation_err.msg = \"123 is not of type \
             \\\"string\\\"\"; path = \".name\"; }; ]"
            (errors
            = [
                {
                  Jsonschema_check.Validation_err.msg = "123 is not of type \"string\"";
                  path = ".name";
                };
              ]))

let test_invalid2 =
  Oth.test ~name:"invalid2" (fun _ ->
      let schema =
        {|{"type": "object", "properties": {"name": {"type": "string"}, "bar": {"type": "integer"}}, "required": ["bar"]}|}
      in
      let valid_json = {|{"name": "foo", "bar": "hi"}|} in
      match Jsonschema_check.validate_json_schema ~schema valid_json with
      | Ok () -> Oth.Assert.false_ "invalid2: unexpected value"
      | Error errors ->
          Oth.Assert.true_
            "errors = [ { Jsonschema_check.Validation_err.msg = \"\\\"hi\\\" is not of type \
             \\\"integer\\\"\"; path = \".bar\"; }; ]"
            (errors
            = [
                {
                  Jsonschema_check.Validation_err.msg = "\"hi\" is not of type \"integer\"";
                  path = ".bar";
                };
              ]))

let test_invalid3 =
  Oth.test ~name:"invalid3" (fun _ ->
      let schema =
        {|{"type": "object", "properties": {"name": {"type": "string"}, "bar": {"type": "object", "properties": {"foo": {"type": "integer"}}}}}|}
      in
      let valid_json = {|{"name": "foo", "bar": {"foo": "baz"}}|} in
      match Jsonschema_check.validate_json_schema ~schema valid_json with
      | Ok () -> Oth.Assert.false_ "invalid3: unexpected value"
      | Error errors ->
          Oth.Assert.true_
            "errors = [ { Jsonschema_check.Validation_err.msg = \"\\\"baz\\\" is not of type \
             \\\"integer\\\"\"; path = \".bar.foo\"; }; ]"
            (errors
            = [
                {
                  Jsonschema_check.Validation_err.msg = "\"baz\" is not of type \"integer\"";
                  path = ".bar.foo";
                };
              ]))

let test = Oth.parallel [ test_valid; test_invalid; test_invalid2; test_invalid3 ]

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
