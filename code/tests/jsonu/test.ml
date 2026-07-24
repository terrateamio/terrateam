let test_bool =
  Oth.test ~name:"Test Bool" (fun _ ->
      let base = `Bool true in
      let override = `Bool false in
      assert (Jsonu.merge ~base override = Ok (`Bool false));
      let base = `Bool false in
      let override = `Bool true in
      assert (Jsonu.merge ~base override = Ok (`Bool true));
      let base = `Null in
      let override = `Bool true in
      assert (Jsonu.merge ~base override = Ok (`Bool true));
      let base = `Bool true in
      let override = `Null in
      assert (Jsonu.merge ~base override = Ok `Null))

let test_int =
  Oth.test ~name:"Test Integer" (fun _ ->
      let base = `Int 1 in
      let override = `Int 2 in
      assert (Jsonu.merge ~base override = Ok (`Int 2));
      let base = `Null in
      let override = `Int 1 in
      assert (Jsonu.merge ~base override = Ok (`Int 1));
      let base = `Int 1 in
      let override = `Null in
      assert (Jsonu.merge ~base override = Ok `Null);
      let base = `Intlit "1" in
      let override = `Int 1 in
      assert (Jsonu.merge ~base override = Ok (`Int 1));
      let base = `Int 1 in
      let override = `Intlit "1" in
      assert (Jsonu.merge ~base override = Ok (`Intlit "1")))

let test_list =
  Oth.test ~name:"Test List" (fun _ ->
      let base = `List [ `Int 1; `Int 2 ] in
      let override = `List [ `Int 3; `Int 4 ] in
      assert (Jsonu.merge ~base override = Ok (`List [ `Int 3; `Int 4; `Int 1; `Int 2 ])))

let test_assoc =
  Oth.test ~name:"Test Assoc" (fun _ ->
      let base = `Assoc [ ("foo", `Int 1); ("bar", `String "foo") ] in
      let override = `Assoc [ ("foo", `Int 2); ("bar", `String "baz") ] in
      let res = CCResult.get_exn (Jsonu.merge ~base override) in
      assert (Yojson.Safe.Util.member "foo" res = `Int 2);
      assert (Yojson.Safe.Util.member "bar" res = `String "baz"))

let test_assoc_extra_keys_in_base =
  Oth.test ~name:"Test Assoc extra keys in base" (fun _ ->
      let base = `Assoc [ ("foo", `Int 1); ("bar", `String "foo") ] in
      let override = `Assoc [ ("foo", `Int 2) ] in
      let res = CCResult.get_exn (Jsonu.merge ~base override) in
      assert (Yojson.Safe.Util.member "foo" res = `Int 2);
      assert (Yojson.Safe.Util.member "bar" res = `String "foo"))

let test_type_mismatch_err =
  Oth.test ~name:"Test type mismatch err" (fun _ ->
      let base = `Int 1 in
      let override = `String "foo" in
      assert (Jsonu.merge ~base override = Error (`Type_mismatch_err (None, `Int 1, `String "foo")));
      let base = `Assoc [ ("k", `Int 1) ] in
      let override = `Assoc [ ("k", `String "foo") ] in
      assert (
        Jsonu.merge ~base override = Error (`Type_mismatch_err (Some "k", `Int 1, `String "foo")));
      let base = `Assoc [ ("j", `Assoc [ ("k", `Int 1) ]) ] in
      let override = `Assoc [ ("j", `Assoc [ ("k", `String "foo") ]) ] in
      assert (
        Jsonu.merge ~base override = Error (`Type_mismatch_err (Some "j.k", `Int 1, `String "foo"))))

let test_null_is_identity =
  Oth.test ~name:"Test null_is_identity" (fun _ ->
      (* null override preserves base when null_is_identity is true *)
      assert (Jsonu.merge ~null_is_identity:true ~base:(`Bool true) `Null = Ok (`Bool true));
      assert (Jsonu.merge ~null_is_identity:true ~base:(`Int 1) `Null = Ok (`Int 1));
      assert (Jsonu.merge ~null_is_identity:true ~base:(`String "s") `Null = Ok (`String "s"));
      (* null base is still replaced by override *)
      assert (Jsonu.merge ~null_is_identity:true ~base:`Null (`Int 1) = Ok (`Int 1));
      (* null base with null override stays null *)
      assert (Jsonu.merge ~null_is_identity:true ~base:`Null `Null = Ok `Null);
      (* nested: null override in assoc preserves base value *)
      let base = `Assoc [ ("foo", `Int 1); ("bar", `String "hello") ] in
      let override = `Assoc [ ("foo", `Null) ] in
      let res = CCResult.get_exn (Jsonu.merge ~null_is_identity:true ~base override) in
      assert (Yojson.Safe.Util.member "foo" res = `Int 1);
      assert (Yojson.Safe.Util.member "bar" res = `String "hello");
      (* default behavior unchanged: null override replaces base *)
      assert (Jsonu.merge ~base:(`Bool true) `Null = Ok `Null);
      assert (Jsonu.merge ~base:(`Int 1) `Null = Ok `Null);
      ())

let test_list_append =
  Oth.test ~name:"Test list_append" (fun _ ->
      let base = `List [ `Int 1; `Int 2 ] in
      let override = `List [ `Int 3; `Int 4 ] in
      (* list_append: override appended to base *)
      assert (
        Jsonu.merge ~list_append:true ~base override = Ok (`List [ `Int 1; `Int 2; `Int 3; `Int 4 ]));
      (* default: override prepended to base *)
      assert (Jsonu.merge ~base override = Ok (`List [ `Int 3; `Int 4; `Int 1; `Int 2 ]));
      ())

let test_both_params =
  Oth.test ~name:"Test null_is_identity and list_append combined" (fun _ ->
      let base =
        `Assoc [ ("items", `List [ `Int 1 ]); ("name", `String "base"); ("extra", `Int 42) ]
      in
      let override = `Assoc [ ("items", `List [ `Int 2 ]); ("name", `Null) ] in
      let res =
        CCResult.get_exn (Jsonu.merge ~null_is_identity:true ~list_append:true ~base override)
      in
      (* list appended *)
      assert (Yojson.Safe.Util.member "items" res = `List [ `Int 1; `Int 2 ]);
      (* null override preserves base *)
      assert (Yojson.Safe.Util.member "name" res = `String "base");
      (* keys only in base are kept *)
      assert (Yojson.Safe.Util.member "extra" res = `Int 42);
      ())

let test =
  Oth.parallel
    [
      test_bool;
      test_int;
      test_list;
      test_assoc;
      test_assoc_extra_keys_in_base;
      test_type_mismatch_err;
      test_null_is_identity;
      test_list_append;
      test_both_params;
    ]

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ test
