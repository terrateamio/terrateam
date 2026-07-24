module U = Yojson.Safe.Util

let flatten = Json_schema_flatten.flatten_document
let load = Yojson.Safe.from_file
let def name j = U.member name (U.member "definitions" j)
let prop p obj = U.member p (U.member "properties" obj)
let ref_of node = U.to_string (U.member "$ref" node)
let present node = node <> `Null

(* Default mode: a foreign ref is inlined under a stem-namespaced canonical name and its ref is
   rewritten to an internal one.  Local and transitive refs behave as expected. *)
let test_inline =
  Oth.test ~name:"Inline foreign ref (default)" (fun _ ->
      let flat = flatten ~search_path:[] ~file_link:[] ~root_file:"main.json" (load "main.json") in
      let person = def "Person" flat in
      (* foreign ref rewritten to internal canonical *)
      Oth.Assert.Eq.string
        ~expected:"#/definitions/common_address"
        ~actual:(ref_of (prop "address" person));
      (* local ref untouched *)
      Oth.Assert.Eq.string ~expected:"#/definitions/Place" ~actual:(ref_of (prop "home" person));
      (* foreign definition pulled in *)
      Oth.Assert.true_ "common_address inlined" (present (def "common_address" flat));
      (* transitive foreign ref pulled in and rewritten *)
      Oth.Assert.Eq.string
        ~expected:"#/definitions/deep_zip"
        ~actual:(ref_of (prop "zip" (def "common_address" flat)));
      Oth.Assert.true_ "deep_zip inlined" (present (def "deep_zip" flat)))

(* --file-link mode: the ref points at an existing module and the file is neither loaded nor
   inlined (so its transitive deps are not pulled in either). *)
let test_file_link =
  Oth.test ~name:"File-link foreign ref" (fun _ ->
      let flat =
        flatten
          ~search_path:[]
          ~file_link:[ ("common.json", "Common") ]
          ~root_file:"main.json"
          (load "main.json")
      in
      let person = def "Person" flat in
      Oth.Assert.Eq.string
        ~expected:"#/file-link/Common/Address"
        ~actual:(ref_of (prop "address" person));
      (* not inlined *)
      Oth.Assert.true_ "common_address not inlined" (not (present (def "common_address" flat)));
      (* common.json was never loaded, so its transitive dep is absent too *)
      Oth.Assert.true_ "deep_zip absent" (not (present (def "deep_zip" flat))))

(* The search path is consulted when the ref cannot be found next to the referencing file. *)
let test_search_path =
  Oth.test ~name:"Foreign ref resolved via search path" (fun _ ->
      let flat =
        flatten ~search_path:[ "sub" ] ~file_link:[] ~root_file:"main2.json" (load "main2.json")
      in
      Oth.Assert.Eq.string
        ~expected:"#/definitions/lib_x"
        ~actual:(ref_of (prop "x" (def "Root" flat)));
      Oth.Assert.true_ "lib_x inlined" (present (def "lib_x" flat)))

(* Mutually-recursive foreign files terminate and both definitions are inlined. *)
let test_cycle =
  Oth.test ~name:"Cyclic foreign refs terminate" (fun _ ->
      let flat = flatten ~search_path:[] ~file_link:[] ~root_file:"a.json" (load "a.json") in
      Oth.Assert.Eq.string ~expected:"#/definitions/b_b" ~actual:(ref_of (prop "b" (def "A" flat)));
      Oth.Assert.Eq.string
        ~expected:"#/definitions/a_a"
        ~actual:(ref_of (prop "a" (def "b_b" flat)));
      Oth.Assert.true_ "a_a inlined" (present (def "a_a" flat)))

(* An unresolvable foreign file is a hard error. *)
let test_missing_file =
  Oth.test ~name:"Missing foreign file raises" (fun _ ->
      let raised =
        try
          ignore (flatten ~search_path:[] ~file_link:[] ~root_file:"main2.json" (load "main2.json"));
          false
        with Failure _ -> true
      in
      Oth.Assert.true_ "missing foreign file raises" raised)

let test =
  Oth.parallel [ test_inline; test_file_link; test_search_path; test_cycle; test_missing_file ]

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ test
