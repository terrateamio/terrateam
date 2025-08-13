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

let test_invalid2 =
  Oth.test ~name:"invalid2" (fun _ ->
      let template = "Hello {% for bar %} {% endfor %} " in
      let bindings = `Assoc [ ("name", `String "user") ] in
      assert (
        Minijinja.render_template template bindings
        = Error
            {|Template parse error: syntax error: unexpected end of block, expected in (in template:1)|}))

let test_missing_value =
  Oth.test ~name:"missing value" (fun _ ->
      let template = "Hello {{ name }}" in
      let bindings = `Assoc [] in
      assert (
        Minijinja.render_template template bindings
        = Error {|Render error: undefined value (in template:1)|}))

let test = Oth.parallel [ test_valid; test_invalid; test_invalid2; test_missing_value ]

let () =
  Random.self_init ();
  Oth.run test
