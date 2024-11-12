let test_tokenizer1 =
  Oth.test ~desc:"Basic tokenizer" ~name:"Tokenizer: Simple replace" (fun _ ->
      let template = "@name@" in
      let lexbuf = Sedlexing.Utf8.from_string template in
      let tokens = CCResult.get_exn (Snabela_lexer.tokenize lexbuf) in
      assert (Snabela_lexer.Token.(equal tokens [ At 1; Key "name"; At 1 ])))

let test_tokenizer2 =
  Oth.test ~desc:"Tokenize transformer" ~name:"Tokenizer: Transformer" (fun _ ->
      let template = "@name | foo@" in
      let lexbuf = Sedlexing.Utf8.from_string template in
      let tokens = CCResult.get_exn (Snabela_lexer.tokenize lexbuf) in
      assert (Snabela_lexer.Token.(equal tokens [ At 1; Key "name"; Transformer "foo"; At 1 ])))

let test_tokenizer3 =
  Oth.test ~desc:"Just a string" ~name:"Tokenizer: String" (fun _ ->
      let template = "Hello" in
      let lexbuf = Sedlexing.Utf8.from_string template in
      let tokens = CCResult.get_exn (Snabela_lexer.tokenize lexbuf) in
      assert (Snabela_lexer.Token.(equal tokens [ String "Hello" ])))

let test_tokenizer4 =
  Oth.test ~desc:"Empty input" ~name:"Tokenizer: Empty" (fun _ ->
      let template = "" in
      let lexbuf = Sedlexing.Utf8.from_string template in
      let tokens = CCResult.get_exn (Snabela_lexer.tokenize lexbuf) in
      assert (Snabela_lexer.Token.(equal tokens [])))

let test_tokenizer5 =
  Oth.test ~desc:"Left right trim" ~name:"Tokenizer: Trim" (fun _ ->
      let template = "@- test -@" in
      let lexbuf = Sedlexing.Utf8.from_string template in
      let tokens = CCResult.get_exn (Snabela_lexer.tokenize lexbuf) in
      assert (Snabela_lexer.Token.(equal tokens [ At 1; Left_trim; Key "test"; Right_trim; At 1 ])))

let test_tokenizer6 =
  Oth.test ~name:"Tokenizer: Invalid" (fun _ ->
      try
        let template = "@- te st -@" in
        let lexbuf = Sedlexing.Utf8.from_string template in
        ignore (Snabela_lexer.tokenize lexbuf);
        assert false
      with _ -> ())

let test_tokenizer7 =
  Oth.test ~name:"Tokenizer: Basic" (fun _ ->
      let template = "Hello, @name@" in
      let lexbuf = Sedlexing.Utf8.from_string template in
      let tokens = CCResult.get_exn (Snabela_lexer.tokenize lexbuf) in
      assert (Snabela_lexer.Token.(equal tokens [ String "Hello, "; At 1; Key "name"; At 1 ])))

let test_tokenizer8 =
  Oth.test ~name:"Tokenizer: README" (fun _ ->
      let template =
        "@#parties-@\n\
         @name@ has a minimum age of @min_age@.\n\
         @#?guest_list-@\n\
        \  Guest list:\n\
        \  @-#guest_list-@\n\
        \    @name@\n\
        \  @-/guest_list-@\n\
         @/guest_list-@\n\
         @#!guest_list-@\n\
        \  No guests have signed up.\n\
         @/guest_list-@\n\
         @/parties-@"
      in
      let lexbuf = Sedlexing.Utf8.from_string template in
      let tokens = CCResult.get_exn (Snabela_lexer.tokenize lexbuf) in
      assert (
        Snabela_lexer.Token.(
          equal
            tokens
            [
              At 1;
              List;
              Key "parties";
              Right_trim;
              At 1;
              String "\n";
              At 2;
              Key "name";
              At 2;
              String " has a minimum age of ";
              At 2;
              Key "min_age";
              At 2;
              String ".\n";
              At 3;
              List;
              Test;
              Key "guest_list";
              Right_trim;
              At 3;
              String "\n  Guest list:\n  ";
              At 5;
              Left_trim;
              List;
              Key "guest_list";
              Right_trim;
              At 5;
              String "\n    ";
              At 6;
              Key "name";
              At 6;
              String "\n  ";
              At 7;
              Left_trim;
              End_section;
              Key "guest_list";
              Right_trim;
              At 7;
              String "\n";
              At 8;
              End_section;
              Key "guest_list";
              Right_trim;
              At 8;
              String "\n";
              At 9;
              List;
              Neg_test;
              Key "guest_list";
              Right_trim;
              At 9;
              String "\n  No guests have signed up.\n";
              At 11;
              End_section;
              Key "guest_list";
              Right_trim;
              At 11;
              String "\n";
              At 12;
              End_section;
              Key "parties";
              Right_trim;
              At 12;
            ])))

let test_tokenizer9 =
  Oth.test ~name:"Tokenizer: Key test" (fun _ ->
      let template = "Hello, @^name@@name@@/name@" in
      let lexbuf = Sedlexing.Utf8.from_string template in
      let tokens = CCResult.get_exn (Snabela_lexer.tokenize lexbuf) in
      assert (
        Snabela_lexer.Token.(
          equal
            tokens
            [
              String "Hello, ";
              At 1;
              Exists;
              Test;
              Key "name";
              At 1;
              At 1;
              Key "name";
              At 1;
              At 1;
              End_section;
              Key "name";
              At 1;
            ])))

let test_apply1 =
  Oth.test ~name:"Apply: Simple" (fun _ ->
      let template = "Hello, @name@" in
      let kv = Snabela.Kv.(Map.of_list [ ("name", string "foo") ]) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let applied = CCResult.get_exn (Snabela.apply compile kv) in
      assert ("Hello, foo" = applied))

let test_apply2 =
  Oth.test ~name:"Apply: Boolean true" (fun _ ->
      let template = "Hello, @?personalize-@ @name@ @-/personalize@" in
      let kv = Snabela.Kv.(Map.of_list [ ("name", string "foo"); ("personalize", bool true) ]) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let applied = CCResult.get_exn (Snabela.apply compile kv) in
      assert ("Hello, foo" = applied))

let test_apply3 =
  Oth.test ~name:"Apply: Boolean false" (fun _ ->
      let template = "Hello, @?personalize-@ @name@ @-/personalize@" in
      let kv = Snabela.Kv.(Map.of_list [ ("name", string "foo"); ("personalize", bool false) ]) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let applied = CCResult.get_exn (Snabela.apply compile kv) in
      assert ("Hello, " = applied))

let test_apply4 =
  Oth.test ~name:"Apply: Boolean not true" (fun _ ->
      let template = "Hello, @!personalize-@ @name@ @-/personalize@" in
      let kv = Snabela.Kv.(Map.of_list [ ("name", string "foo"); ("personalize", bool false) ]) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let applied = CCResult.get_exn (Snabela.apply compile kv) in
      assert ("Hello, foo" = applied))

let test_apply5 =
  Oth.test ~name:"Apply: Boolean not false" (fun _ ->
      let template = "Hello, @!personalize-@ @name@ @-/personalize@" in
      let kv = Snabela.Kv.(Map.of_list [ ("name", string "foo"); ("personalize", bool true) ]) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let applied = CCResult.get_exn (Snabela.apply compile kv) in
      assert ("Hello, " = applied))

let test_apply6 =
  Oth.test ~name:"Apply: List non-empty iter" (fun _ ->
      let template = "Hello,\n@#names-@\n@name@\n@-/names@" in
      let kv =
        Snabela.Kv.(
          Map.of_list
            [
              ( "names",
                list
                  [ Map.of_list [ ("name", string "foo") ]; Map.of_list [ ("name", string "bar") ] ]
              );
            ])
      in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let applied = CCResult.get_exn (Snabela.apply compile kv) in
      assert ("Hello,\nfoo\nbar\n" = applied))

let test_apply7 =
  Oth.test ~name:"Apply: List non-empty test" (fun _ ->
      let template = "Hello, @#?names-@ everyone @-/names@" in
      let kv =
        Snabela.Kv.(
          Map.of_list
            [
              ( "names",
                list
                  [ Map.of_list [ ("name", string "foo") ]; Map.of_list [ ("name", string "bar") ] ]
              );
            ])
      in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let applied = CCResult.get_exn (Snabela.apply compile kv) in
      assert ("Hello, everyone" = applied))

let test_apply8 =
  Oth.test ~name:"Apply: List empty test" (fun _ ->
      let template = "Hello, @#!names-@ everyone @-/names@" in
      let kv =
        Snabela.Kv.(
          Map.of_list
            [
              ( "names",
                list
                  [ Map.of_list [ ("name", string "foo") ]; Map.of_list [ ("name", string "bar") ] ]
              );
            ])
      in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let applied = CCResult.get_exn (Snabela.apply compile kv) in
      assert ("Hello, " = applied))

let test_apply9 =
  Oth.test ~name:"Apply: README Test" (fun _ ->
      let template =
        "@#parties-@\n\
         @name@ has a minimum age of @min_age@.\n\
         @#?guest_list-@\n\
        \  Guest list:\n\
        \  @-#guest_list-@\n\
        \    @name@\n\
        \  @-/guest_list-@\n\
         @/guest_list-@\n\
         @#!guest_list-@\n\
        \  No guests have signed up.\n\
         @/guest_list-@\n\
         @/parties-@"
      in
      let kv =
        Snabela.Kv.(
          Map.of_list
            [
              ("min_age", int 18);
              ("guest_list", list []);
              ( "parties",
                list
                  [
                    Map.of_list
                      [
                        ("name", string "End of the world party");
                        ( "guest_list",
                          list
                            [
                              Map.of_list [ ("name", string "me") ];
                              Map.of_list [ ("name", string "myself") ];
                              Map.of_list [ ("name", string "i") ];
                            ] );
                      ];
                    Map.of_list
                      [ ("name", string "End of the world party party"); ("min_age", int 21) ];
                  ] );
            ])
      in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let applied = CCResult.get_exn (Snabela.apply compile kv) in
      let expected =
        "End of the world party has a minimum age of 18.\n\
        \  Guest list:\n\
        \    me\n\
        \    myself\n\
        \    i\n\
         End of the world party party has a minimum age of 21.\n\
        \  No guests have signed up.\n"
      in
      assert (expected = applied))

let test_apply10 =
  Oth.test ~name:"Apply: List non-empty test on empty list" (fun _ ->
      let template = "Hello, @#?names-@ everyone @-/names@" in
      let kv = Snabela.Kv.(Map.of_list [ ("names", list []) ]) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let applied = CCResult.get_exn (Snabela.apply compile kv) in
      assert ("Hello, " = applied))

let test_apply11 =
  Oth.test ~name:"Apply: Default transformer" (fun _ ->
      let template = "Hello, @name@" in
      let kv = Snabela.Kv.(Map.of_list [ ("name", string "joe") ]) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let capitalize = function
        | Snabela.Kv.S s -> Snabela.Kv.S (CCString.capitalize_ascii s)
        | _ -> raise (Invalid_argument "not a string")
      in
      let compile = Snabela.of_template ~append_transformers:[ capitalize ] t [] in
      let applied = CCResult.get_exn (Snabela.apply compile kv) in
      assert ("Hello, Joe" = applied))

let test_apply12 =
  Oth.test ~name:"Apply: Comment" (fun _ ->
      let template = "@%This is a template-@\nHello, @name@" in
      let kv = Snabela.Kv.(Map.of_list [ ("name", string "foo") ]) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let applied = CCResult.get_exn (Snabela.apply compile kv) in
      assert ("Hello, foo" = applied))

let test_apply13 =
  Oth.test ~name:"Apply: Key test" (fun _ ->
      let template = "Hello, @^name@@name@@/name@" in
      let kv = Snabela.Kv.(Map.of_list [ ("name", string "foo") ]) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let applied = CCResult.get_exn (Snabela.apply compile kv) in
      assert ("Hello, foo" = applied))

let test_apply14 =
  Oth.test ~name:"Apply: Neg key test" (fun _ ->
      let template = "Hello, @^!name@bar@/name@" in
      let kv = Snabela.Kv.(Map.of_list []) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let applied = CCResult.get_exn (Snabela.apply compile kv) in
      assert ("Hello, bar" = applied))

let test_apply15 =
  Oth.test ~name:"Apply: Key equals test" (fun _ ->
      let template = "Hello, @?name=cat@@name@@/name=cat@" in
      let kv = Snabela.Kv.(Map.of_list [ ("name", string "cat") ]) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let applied = CCResult.get_exn (Snabela.apply compile kv) in
      assert ("Hello, cat" = applied))

let test_apply16 =
  Oth.test ~name:"Apply: Key not equals test" (fun _ ->
      let template = "Hello, @?name=cat@@name@@/name=cat@" in
      let kv = Snabela.Kv.(Map.of_list [ ("name", string "foo") ]) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let applied = CCResult.get_exn (Snabela.apply compile kv) in
      assert ("Hello, " = applied))

let test_apply17 =
  Oth.test ~name:"Apply: Key neg equals test" (fun _ ->
      let template = "Hello, @!name=cat@@name@@/name=cat@" in
      let kv = Snabela.Kv.(Map.of_list [ ("name", string "cat") ]) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let applied = CCResult.get_exn (Snabela.apply compile kv) in
      assert ("Hello, " = applied))

let test_apply18 =
  Oth.test ~name:"Apply: Key not neg equals test" (fun _ ->
      let template = "Hello, @!name=cat@@name@@/name=cat@" in
      let kv = Snabela.Kv.(Map.of_list [ ("name", string "foo") ]) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let applied = CCResult.get_exn (Snabela.apply compile kv) in
      assert ("Hello, foo" = applied))

let test_apply_fail1 =
  Oth.test ~name:"Apply Fail: Missing key" (fun _ ->
      let template = "Hello, @name@" in
      let kv = Snabela.Kv.Map.empty in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let ret = Snabela.apply compile kv in
      assert (ret = Error (`Missing_key ("name", 1))))

let test_apply_fail2 =
  Oth.test ~name:"Apply Fail: Expected boolean" (fun _ ->
      let template = "@?greet-@ hello @-/greet@" in
      let kv = Snabela.Kv.(Map.of_list [ ("greet", int 2) ]) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let ret = Snabela.apply compile kv in
      assert (ret = Error (`Expected_boolean ("greet", 1))))

let test_apply_fail3 =
  Oth.test ~name:"Apply Fail: Expected list" (fun _ ->
      let template = "@#?greet-@ hello @-/greet@" in
      let kv = Snabela.Kv.(Map.of_list [ ("greet", int 2) ]) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let ret = Snabela.apply compile kv in
      assert (ret = Error (`Expected_list ("greet", 1))))

let test_apply_fail4 =
  Oth.test ~name:"Apply Fail: Missing transformer" (fun _ ->
      let template = "Hello, @name | test@" in
      let kv = Snabela.Kv.(Map.of_list [ ("name", string "Joe") ]) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let ret = Snabela.apply compile kv in
      assert (ret = Error (`Missing_transformer ("test", 1))))

let test_apply_fail5 =
  Oth.test ~name:"Apply Fail: Non scalar key" (fun _ ->
      let template = "Hello, @name | test@" in
      let kv = Snabela.Kv.(Map.of_list [ ("name", list []) ]) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let ret = Snabela.apply compile kv in
      assert (ret = Error (`Non_scalar_key ("name", 1))))

let test_apply_fail6 =
  Oth.test ~name:"Apply Fail: Missing closing section" (fun _ ->
      let template = "@?foo@ hi" in
      let kv = Snabela.Kv.(Map.of_list [ ("foo", bool true) ]) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let ret = Snabela.apply compile kv in
      assert (ret = Error (`Missing_closing_section "foo")))

let test_apply_fail7 =
  Oth.test ~name:"Apply Fail: Missing key not line 1" (fun _ ->
      let template = "Hello,\n@name@" in
      let kv = Snabela.Kv.Map.empty in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let ret = Snabela.apply compile kv in
      assert (ret = Error (`Missing_key ("name", 2))))

let test_apply_fail8 =
  Oth.test ~name:"Apply Fail: New lines in replacement" (fun _ ->
      let template = "Hello,\n@\n\nname\n\n@\n@name1@" in
      let kv = Snabela.Kv.(Map.of_list [ ("name", string "foo") ]) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let ret = Snabela.apply compile kv in
      assert (ret = Error (`Missing_key ("name1", 7))))

let test_apply_fail9 =
  Oth.test ~name:"Apply Fail: Comment" (fun _ ->
      let template = "@%This is a template-@\nHello, @name@" in
      let kv = Snabela.Kv.(Map.of_list []) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let ret = Snabela.apply compile kv in
      assert (ret = Error (`Missing_key ("name", 2))))

let test_apply_fail10 =
  Oth.test ~name:"Apply Fail: More Comment" (fun _ ->
      let template = "@%This is\na template-@\nHello, @name@" in
      let kv = Snabela.Kv.(Map.of_list []) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let compile = Snabela.of_template t [] in
      let ret = Snabela.apply compile kv in
      assert (ret = Error (`Missing_key ("name", 3))))

let test_apply_fail11 =
  Oth.test ~name:"Apply Fail: Malformed Comment" (fun _ ->
      let template = "@The difference between a valid comment @ and premature closed is subtle@" in
      let t = Snabela.Template.of_utf8_string template in
      assert (t = Error (`Invalid_replacement 1)))

let test_transformer1 =
  Oth.test ~name:"Transformer: Capitalize" (fun _ ->
      let template = "Hello, @name | capitalize@" in
      let kv = Snabela.Kv.(Map.of_list [ ("name", string "foo") ]) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let capitalize = function
        | Snabela.Kv.S s -> Snabela.Kv.S (CCString.capitalize_ascii s)
        | _ -> raise (Invalid_argument "not a string")
      in
      let compile = Snabela.of_template t [ ("capitalize", capitalize) ] in
      let applied = CCResult.get_exn (Snabela.apply compile kv) in
      assert ("Hello, Foo" = applied))

let test_transformer2 =
  Oth.test ~name:"Transformer: Money" (fun _ ->
      let template = "You owe me @ amount | money@@currency@" in
      let kv = Snabela.Kv.(Map.of_list [ ("currency", string "USD"); ("amount", float 1.25) ]) in
      let t = CCResult.get_exn (Snabela.Template.of_utf8_string template) in
      let money = function
        | Snabela.Kv.F f -> Snabela.Kv.S (Printf.sprintf "%0.2f" f)
        | _ -> raise (Invalid_argument "not a float")
      in
      let compile = Snabela.of_template t [ ("money", money) ] in
      let applied = CCResult.get_exn (Snabela.apply compile kv) in
      assert ("You owe me 1.25USD" = applied))

let test =
  Oth.parallel
    [
      test_tokenizer1;
      test_tokenizer2;
      test_tokenizer3;
      test_tokenizer4;
      test_tokenizer5;
      test_tokenizer6;
      test_tokenizer7;
      test_tokenizer8;
      test_tokenizer9;
      test_apply1;
      test_apply2;
      test_apply3;
      test_apply4;
      test_apply5;
      test_apply6;
      test_apply7;
      test_apply8;
      test_apply9;
      test_apply10;
      test_apply11;
      test_apply12;
      test_apply13;
      test_apply14;
      test_apply15;
      test_apply16;
      test_apply17;
      test_apply18;
      test_apply_fail1;
      test_apply_fail2;
      test_apply_fail3;
      test_apply_fail4;
      test_apply_fail5;
      test_apply_fail6;
      test_apply_fail7;
      test_apply_fail8;
      test_apply_fail9;
      test_apply_fail10;
      test_apply_fail11;
      test_transformer1;
      test_transformer2;
    ]

let () =
  Random.self_init ();
  Oth.run test
