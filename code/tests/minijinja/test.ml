let test_valid =
  Oth.test ~name:"valid" (fun _ ->
      let template = "Hello {{ name }}" in
      let bindings = `Assoc [ ("name", `String "user") ] in
      assert (Minijinja.render_template template bindings = Ok "Hello user"))

let test_invalid =
  Oth.test ~name:"invalid" (fun _ ->
      let template = "Hello {{ name " in
      let bindings = `Assoc [ ("name", `String "user") ] in
      assert (
        Minijinja.render_template template bindings
        = Error
            {|Template parse error: syntax error: unexpected end of input, expected end of variable block (in template:1)|}))

let test = Oth.parallel [ test_valid; test_invalid ]

let () =
  Random.self_init ();
  Oth.run test
