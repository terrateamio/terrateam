module String_map = CCMap.Make (CCString)

let test_no_subst =
  Oth.test ~name:"no_subst" (fun _ ->
      let vars = CCFun.const None in
      assert (Str_template.apply vars "foo" = Ok "foo"))

let test_one_subst =
  Oth.test ~name:"one_subst" (fun _ ->
      let vars = CCFun.flip String_map.find_opt @@ String_map.of_list [ ("foo", "bar") ] in
      assert (Str_template.apply vars "${foo}" = Ok "bar"))

let test_two_subst =
  Oth.test ~name:"two_subst" (fun _ ->
      let vars = CCFun.flip String_map.find_opt @@ String_map.of_list [ ("foo", "bar") ] in
      assert (Str_template.apply vars "${foo}${foo}" = Ok "barbar"))

let test_complicated_subst =
  Oth.test ~name:"complicated_subst" (fun _ ->
      let vars =
        CCFun.flip String_map.find_opt
        @@ String_map.of_list [ ("name", "person"); ("job", "manual laborer") ]
      in
      assert (
        Str_template.apply vars "Hello ${name}, welcome to your first day as a ${job}."
        = Ok "Hello person, welcome to your first day as a manual laborer."))

let test_escape =
  Oth.test ~name:"escape" (fun _ ->
      let vars = CCFun.const None in
      assert (Str_template.apply vars "$${foo}" = Ok "${foo}"))

let test_complicated_escape =
  Oth.test ~name:"complicated_escape" (fun _ ->
      let vars =
        CCFun.flip String_map.find_opt
        @@ String_map.of_list [ ("name", "person"); ("job", "manual laborer") ]
      in
      assert (
        Str_template.apply
          vars
          "Hello ${name}, welcome to your first day as a ${job}.  Don't forget you can escape like \
           $${this}."
        = Ok
            "Hello person, welcome to your first day as a manual laborer.  Don't forget you can \
             escape like ${this}."))

let test =
  Oth.parallel
    [
      test_no_subst;
      test_one_subst;
      test_two_subst;
      test_complicated_subst;
      test_escape;
      test_complicated_escape;
    ]

let () =
  Random.self_init ();
  Oth.run test
